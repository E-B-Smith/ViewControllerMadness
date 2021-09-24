import UIKit

/// Sent each time a view controller's view did appear.
/// The notification sender is the UIViewController that appeared.
public let UIViewControllerViewDidAppear = NSNotification.Name("XUIViewControllerViewDidAppear")

/// Sent each time a view controller's view disappears.
/// The notification sender is the UIViewController that appeared.
public let UIViewControllerViewDidDisappear = NSNotification.Name("XUIViewControllerViewDidDisappear")

fileprivate typealias boolVoidType = @convention(c) (AnyObject, Selector, Bool) -> Void
fileprivate typealias viewControllerVoidType = @convention(c) (AnyObject, Selector, UIViewController?) -> Void

// MARK: -

/// This UIViewController used for swizzling only. Not for instantiation.
public class UIViewControllerNotifications: UIViewController {

    private static var oldViewDidAppear: boolVoidType?

    public override func viewDidAppear(_ animated: Bool) {
        Self.oldViewDidAppear?(self, #selector(viewDidAppear(_:)), animated)
        print("viewDidAppear: \(self) Title: \(self.title ?? "<nil>")")
        NotificationCenter.default.post(name: UIViewControllerViewDidAppear, object: self)
    }

    // MARK: -

    private static var oldViewDidDisappear: boolVoidType?

    public override func viewDidDisappear(_ animated: Bool) {
        Self.oldViewDidDisappear?(self, #selector(viewDidDisappear(_:)), animated)
        NotificationCenter.default.post(name: UIViewControllerViewDidDisappear, object: self)
    }

    private static func typedSwizzle<T>(_ selector: Selector) -> T {
        let imp = swizzle(
            class: UIViewController.self,
            selector: selector,
            implementation: self.instanceMethod(for: selector)
        )
        return unsafeBitCast(imp, to: T.self)
    }

    /// Call this class method at app initialization to start the notifications.
    public static func startNotifications() {
        oldViewDidAppear = typedSwizzle(#selector(viewDidAppear(_:)))
        oldViewDidDisappear = typedSwizzle(#selector(viewDidDisappear(_:)))
    }
}
