import UIKit

extension String {
    var capitalizingFirstLetter: String {
        guard self.count > 0 else { return "" }
        return prefix(1).capitalized + dropFirst()
    }
}

extension UIWindow {
    static var activeWindow: UIWindow? {
        for scene in UIApplication.shared.connectedScenes
                where scene.activationState == .foregroundActive {
            if let windows = (scene as? UIWindowScene)?.windows {
                return windows.first(where: { $0.isKeyWindow })
            }
        }
        return nil
    }
}

protocol BasicViewControllerDelegate: AnyObject {
    func dismiss(basicController: BasicViewController)
}

// MARK: -

class ViewControllerTracker {

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presented(_:)),
            name: UIViewControllerDidPresent,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dismissed(_:)),
            name: UIViewControllerDidDismiss,
            object: nil
        )
    }

    private enum ViewControllerState: String {
        case presented
        case dismissed
    }

    private struct ViewControllerInfo {
        var state: ViewControllerState
        var order: Int
        var title: String
    }

    private var order: Int = 0
    private var viewControllers = [String:ViewControllerInfo]()
    public static let shared = ViewControllerTracker()

    @objc func presented(_ notification: NSNotification) {
        guard let sender = notification.object as? UIViewController else {
            fatalError("Notification \(notification.name) has no ViewController object.")
        }
        if sender.view.accessibilityIdentifier == nil {
            sender.view.accessibilityIdentifier = "VC \(order)"
        }
        let vid = sender.view.accessibilityIdentifier ?? "<nil>"
        switch viewControllers[vid]?.state {
        case .presented:
            fatalError("Did present: View controller \(sender.title ?? "<no-title>") has already been presented.")
        case .dismissed:
            fatalError("Did present: View controller \(sender.title ?? "<no-title>") has already been dismissed.")
        default:
            order += 1
            viewControllers[vid] = ViewControllerInfo(
                state: .presented,
                order: order,
                title: "\(sender.self)-\(sender.title ?? "<nil>")"
            )
        }
    }

    @objc func dismissed(_ notification: NSNotification) {
        guard let sender = notification.object as? UIViewController else {
            fatalError("Notification \(notification.name) has no ViewController object.")
        }
        if let vid = sender.view.accessibilityIdentifier {
            switch viewControllers[vid]?.state {
            case .presented:
                viewControllers[vid]?.state = .dismissed
            case .dismissed:
                fatalError("Did dismiss: View controller \(sender.title ?? "<no-title>") has already been dismissed.")
            default:
                fatalError("Did dismiss: View controller \(sender.title ?? "<no-title>") has not been presented.")
            }
        } else {
            fatalError("Did dismiss: View controller \(sender.title ?? "<no-title>") has not been presented.")
        }
    }

    func reportState() {
        print("\n=====================\n")
        viewControllers
            .filter { $0.1.state == .presented }
            .sorted(by: { $0.1.order < $1.1.order })
            .forEach({ id, state in
                print("\(id)\t\(state.order)\t\(state.state)\t\(state.title)")
        })
        print("\n=====================\n")
    }
}

// MARK: -

class BasicViewController: UIViewController {

    // MARK: Properties & Constructors

    static var controllerCount: Int = 0
    static var viewControllers = [ObjectIdentifier:String]()

    static func withNavigationController(
        delegate: BasicViewControllerDelegate? = nil
    ) -> UINavigationController {
        let vc = Self.fromNib()
        vc.delegate = delegate
        return UINavigationController(rootViewController: vc)
    }

    static func fromNib() -> BasicViewController {
        return loadFromNib() as BasicViewController
    }

    @IBOutlet weak var titleLabel: UILabel!

    override var title: String? {
        didSet {
            if self.isViewLoaded {
                titleLabel.text = self.title
            }
        }
    }

    func postLifeCycleNotification(_ methodName: String = #function) {
        let name = "LC-UIViewController" + methodName.capitalizingFirstLetter
        NotificationCenter.default.post(name: NSNotification.Name(name), object: self)
    }

    func showCloseButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeAction(_:))
        )
    }

    public weak var delegate: BasicViewControllerDelegate?

    @IBAction func closeAction(_ sender: Any?) {
        self.delegate?.dismiss(basicController: self)
    }

    // MARK: - View Controller Life Cycle Overrides

    /// Create a view here. If no view is created iOS creates one for you. If a nib exists with the same name
    /// the view is loaded from there.
    override func loadView() {
        super.loadView()
        postLifeCycleNotification()
    }

    /// Called after the view has been created.
    override func viewDidLoad() {
        super.viewDidLoad()
        postLifeCycleNotification()
        Self.controllerCount += 1
        self.title = "View Controller \(String(format:"%3d", Self.controllerCount))"
    }

    /// Called when the view may appear (but still may be cancelled).
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        postLifeCycleNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        postLifeCycleNotification()
        // self.navigationController?.presentationController?.delegate = self
        if self.tabBarController != nil {
        } else
        if let navVC = self.navigationController {
            if navVC.viewControllers.count == 1 {
                showCloseButton()
            }
        } else {
            showCloseButton()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        postLifeCycleNotification()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        postLifeCycleNotification()
        if parent == nil {
            postLifeCycleNotification("parent nil")
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        postLifeCycleNotification()
        if parent == nil {
            postLifeCycleNotification("parent nil")
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        postLifeCycleNotification()
        if parent == nil {
            postLifeCycleNotification("parent nil")
        }
    }

    override func removeFromParent() {
        super.removeFromParent()
        postLifeCycleNotification()
    }

    deinit {
        postLifeCycleNotification()
        print("Deinit \(title ?? "")")
    }

    // MARK: - Actions

    @IBAction func pushAction(_ sender: Any) {
        let vc = Self.fromNib()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func presentAction(_ sender: Any) {
        let vc = BasicViewController.withNavigationController(delegate: self)
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func modalAction(_ sender: Any) {
        let vc = Self.withNavigationController(delegate: self)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func alertAction(_ sender: Any) {
        Self.controllerCount += 1
        let alert = UIAlertController(
            title: "View Controller \(Self.controllerCount)",
            message: "This is an alert.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            Log(.log, "The 'OK' alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func unwindAction(_ sender: Any) {
        UIWindow.activeWindow?.rootViewController?.dismiss(animated: true, completion: {
            var root = UIWindow.activeWindow?.rootViewController
            if let tabs = root as? UITabBarController {
                root = tabs.selectedViewController
            }
            if let root = root as? UINavigationController {
                root.popToRootViewController(animated: true)
            }
        })
    }

    @IBAction func clearLogAction(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("ClearLog"), object: self)
    }

    /*
    @IBAction func reportViewControllersAction(_ sender: Any) {
        print("\n=====================\n")
        Self.viewControllers.sorted(by: { $0.1 < $1.1 }).forEach({ id, title in
            print("\(id)\t\t\(title)")
        })
        print("\n=====================\n")
    }
    */

    @IBAction func reportViewControllersAction(_ sender: Any) {
        ViewControllerTracker.shared.reportState()
    }
}

//  MARK: - BasicViewControllerDelegate

extension BasicViewController: BasicViewControllerDelegate {
    func dismiss(basicController: BasicViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}

//  MARK: - UIAdaptivePresentationControllerDelegate

extension BasicViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.postLifeCycleNotification()
    }
}

// MARK: - UIViewControllerPresenting

extension BasicViewController: UIViewControllerPresenting {

    func viewControllerDidPresent() {
        let id =  ObjectIdentifier(self)
        if let title = Self.viewControllers[id] {
            fatalError("Already presented '\(title)'.")
        }
        Self.viewControllers[id] = self.title
    }

    func viewControllerDidDismiss() {
        let id =  ObjectIdentifier(self)
        if Self.viewControllers[id] == nil {
            fatalError("Already dismissed '\(self.title ?? "<Untitled>")'.")
        }
        Self.viewControllers.removeValue(forKey: id)
    }
}

// MARK: - AnalyticsNaming

extension BasicViewController: AnalyticsNaming {
    var analyticsName: String { return "basic_view_controller" }
}
