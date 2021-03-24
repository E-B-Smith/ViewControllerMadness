import UIKit

struct Note {
    let name: String
    let sender: String
    let source: String
    var userInfo: [AnyHashable:Any]?

    // Clear the userInfo so that references are released.
    mutating func releasseUserInfo() {
        userInfo = nil
    }
}

// MARK: -

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}

// MARK: -

func notificationCallback(
    _ center: CFNotificationCenter?,
    _ observer: UnsafeMutableRawPointer?,
    _ name: CFNotificationName?,
    _ sender: UnsafeRawPointer?,    // Not actually passed by the OS: Crash if accessed.
    _ userInfo: CFDictionary?       // Not actually passed by the OS: Crash if accessed.
) {
    DispatchQueue.main.async {
        guard let obj = observer else { return }
        let observer = Unmanaged<NotificationSpyViewController>.fromOpaque(obj).takeUnretainedValue()
        let nameString: String = name?.rawValue as String? ?? "<nil>"
        let senderString: String = "Darwin"
        let note = Note(name: nameString, sender: senderString, source: "Darwin",  userInfo: nil)
        observer.append(note: note)
    }
}

// MARK: -

class NotificationSpyViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var notes: [Note] = []
    private var ignoredNotifications: Set<String> = [
        "UIViewAnimationDidCommitNotification",
        "UIViewAnimationDidStopNotification",
        "_UIViewHasBaselinePropertyChanged",

        "WillStartSmoothScrolling",
        "DidEndSmoothScrolling",

        "NSBundleDidLoadNotification",

        "UITextSelectionWillScroll",
        "UITextSelectionDidScroll",

        "_UIScrollViewAnimationEndedNotification",
        "_UIScrollViewDidEndDraggingNotification",
        "_UIScrollViewDidEndDeceleratingNotification",
        "_UIScrollViewWillBeginDraggingNotification",

        "_UIApplicationRunLoopModePushNotification",
        "_UIApplicationRunLoopModePopNotification",

        "_UIWindowSystemGestureStateChangedNotification",
        "_UIWindowContentWillRotateNotification",
        "_UIWindowWillMoveToCanvasNotification",
        "_UIWindowDidMoveToCanvasNotification",

        "_UIWindowDidCreateContextNotification",
        "_UIWindowWillBecomeKeyNotification",
        "UIWindowDidBecomeKeyNotification",
        "UIWindowDidResignKeyNotification",
        "UIWindowDidBecomeVisibleNotification",
        "UIWindowFirstResponderDidChangeNotification",

        "UIDeviceOrientationDidChangeNotification",

        "_UIApplicationDidBeginIgnoringInteractionEventsNotification",
        "_UIApplicationDidEndIgnoringInteractionEventsNotification",

        "_UIApplicationWillAddDeactivationReasonNotification",
        "_UIApplicationDidRemoveDeactivationReasonNotification",

        "UIApplicationResumedEventsOnlyNotification",
        "UIApplicationDidBecomeActiveNotification",

        "_AXClearIMPCachesNotification",
        "_UIAppearanceInvocationsDidChangeNotification",

        "NSThreadWillExitNotification",
        "UITextEffectsWindowDidRotateNotification",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationSpyCell.registerFor(tableView: tableView)
        registerForNotifications()
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.darkGray.cgColor
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.scrollToBottom()
        }
    }

    fileprivate func append(note: Note) {
        guard !ignoredNotifications.contains(note.name) else { return }
        if note.name == "ClearLog" {
            notes.removeAll()
            tableView.reloadData()
            return
        }
        Log(.log, String(describing: note))
        var note = note
        note.releasseUserInfo()

        var scrollToBottom = false
        if let indexPath = tableView.indexPathsForVisibleRows?.last {
            scrollToBottom = (indexPath == IndexPath(row: notes.count-1, section: 0))
        }
        notes.append(note)
        let indexPath = IndexPath(row: notes.count-1, section: 0)
        tableView.insertRows(at: [indexPath], with: .none)
        tableView.reloadRows(at: [indexPath], with: .none)
        if scrollToBottom {
            self.scrollToBottom()
        }
    }

    func scrollToBottom() {
        tableView.scrollToRow(
            at: IndexPath(row: notes.count-1, section: 0),
            at: .bottom,
            animated: false
        )
    }

    private var notificationCenterToken: AnyObject?

    public func description(_ object: Any?) -> String {
        guard let object = object else { return "<nil>" }
        return
            String(describing: type(of: object)) + " " +
            ObjectIdentifier(object as AnyObject)
                .debugDescription
                .deletingPrefix("ObjectIdentifier(")
                .deletingSuffix(")")
    }

    private func registerForNotifications() {
        unregisterForNotifications()
        notificationCenterToken = NotificationCenter.default.addObserver(
            forName: nil,
            object: nil,
            queue: nil
        ) { notification in
            var sender = self.description(notification.object)
            if let viewController = notification.object as? UIViewController,
                let title: String = viewController.title,
                title.count > 0 {
                sender = title
            }
            let note = Note(
                name: notification.name.rawValue,
                sender: sender,
                source: "NotificationCenter",
                userInfo: notification.userInfo
            )
            DispatchQueue.main.async {
                self.append(note: note)
            }
        }
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            notificationCallback,
            "com.apple.springboard.ringerstate" as CFString,
            nil,
            .drop
        )
    }

    func unregisterForNotifications() {
        if let token = notificationCenterToken {
            NotificationCenter.default.removeObserver(token)
            notificationCenterToken = nil
        }
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
    }

    deinit {
        unregisterForNotifications()
    }
}

// MARK: - UITableViewDelegate UITableViewDataSource

extension NotificationSpyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: NotificationSpyCell.reuseID, for: indexPath)
            as? NotificationSpyCell
        else { fatalError("Can't dequeue NotificationSpyCell for reuse.") }
        cell.configure(notes[indexPath.row])
        return cell
    }
}
