import UIKit

/// The notification sender is the UIViewController that presented.
public let UIViewControllerDidPresent = NSNotification.Name("UIViewControllerDidPresent")

/// The notification sender is the UIViewController that dismissed.
public let UIViewControllerDidDismiss = NSNotification.Name("UIViewControllerDidDismiss")

/// Adopt this protocol if you want your view controller to receive one of these method calls.
public protocol UIViewControllerPresenting: UIViewController  {
    func viewControllerDidPresent()
    func viewControllerDidDismiss()
}

public extension UIViewControllerPresenting {
    func viewControllerDidPresent() {} // Optional method.
    func viewControllerDidDismiss() {} // Optional method.
}

fileprivate typealias boolVoidType = @convention(c) (AnyObject, Selector, Bool) -> Void
fileprivate typealias viewControllerVoidType = @convention(c) (AnyObject, Selector, UIViewController?) -> Void

/// This UIViewController used for swizzling only. Not for instantiation.
public class UIViewControllerNotifications: UIViewController {

    private static var viewControllers: Set<ObjectIdentifier> = []
    private static var oldViewDidAppear: boolVoidType?

    public override func viewDidAppear(_ animated: Bool) {
        Self.oldViewDidAppear?(self, #selector(viewDidAppear(_:)), animated)
        let identifier = ObjectIdentifier(self)
        guard !Self.viewControllers.contains(identifier) else { return }
        Self.viewControllers.insert(identifier)
        if let presenter = self as? UIViewControllerPresenting {
            presenter.viewControllerDidPresent()
        }
        NotificationCenter.default.post(name: UIViewControllerDidPresent, object: self)
    }

    private static func postDismissNotification(_ viewController: UIViewController) {
        guard viewControllers.contains(ObjectIdentifier(viewController)) else { return }
        viewControllers.remove(ObjectIdentifier(viewController))
        if let presenter = viewController as? UIViewControllerPresenting {
            presenter.viewControllerDidDismiss()
        }
        NotificationCenter.default.post(name: UIViewControllerDidDismiss, object: viewController)
    }

    private static func unwindAndPostDismissNotifications(_ viewController: UIViewController) {
        if let navigationController = (viewController as NSObject) as? UINavigationController {
            for vc in navigationController.viewControllers.reversed() {
                Self.postDismissNotification(vc)
            }
        }
        Self.postDismissNotification(viewController)
    }

    private static var oldViewDidDisappear: boolVoidType?

    public  override func viewDidDisappear(_ animated: Bool) {
        Self.oldViewDidDisappear?(self, #selector(viewDidDisappear(_:)), animated)
        if self.isBeingDismissed {
            Self.unwindAndPostDismissNotifications(self)
        } else
        if self.parent == nil && !((self as UIViewController) is UITabBarController) {
            Self.unwindAndPostDismissNotifications(self)
        } else
        if let nav = self.navigationController, nav.isBeingDismissed {
            Self.unwindAndPostDismissNotifications(nav)
        }
    }

    private static var oldViewDidMove: viewControllerVoidType?

    public override func didMove(toParent parent: UIViewController?) {
        Self.oldViewDidMove?(self, #selector(viewDidDisappear(_:)), parent)
        if parent == nil {
            Self.unwindAndPostDismissNotifications(self)
        }
    }

    private static func typedSwizzle<T>(_ selector: Selector) -> T {
        let imp = swizzle(
            class: UIViewController.self,
            selector: selector,
            implementation: instanceMethod(for: selector)
        )
        return unsafeBitCast(imp, to: T.self)
    }

    /// Call this class method at app initialization to start the notifications.
    public static func start() {
        oldViewDidAppear = typedSwizzle(#selector(viewDidAppear(_:)))
        oldViewDidDisappear = typedSwizzle(#selector(viewDidDisappear(_:)))
        oldViewDidMove = typedSwizzle(#selector(didMove(toParent:)))
    }
}
