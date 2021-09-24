import UIKit

/// Sent immediately after the first time a UIViewController appears.
/// The notification sender is the UIViewController that presented.
public let UIViewControllerDidPresent = NSNotification.Name("XUIViewControllerDidPresent")

/// Sent each time a view controller's view did appear.
/// The notification sender is the UIViewController that appeared.
public let UIViewControllerViewDidAppear = NSNotification.Name("XUIViewControllerViewDidAppear")

/// Sent each time a view controller's view disappears.
/// The notification sender is the UIViewController that appeared.
public let UIViewControllerViewDidDisappear = NSNotification.Name("XUIViewControllerViewDidDisappear")

/// Sent the final time a view controller's view disappears.
/// The notification sender is the UIViewController that dismissed.
public let UIViewControllerDidDismiss = NSNotification.Name("XUIViewControllerDidDismiss")

/// Adopt this protocol if you want your view controller to receive one of these method calls.
@objc protocol UIViewControllerPresenting {
    @objc optional func viewControllerDidPresent()
    @objc optional func viewControllerDidDismiss()
}

// MARK: -

fileprivate class UIViewControllerExtendedProperties {
    weak var viewController: UIViewController?
    var firstAppearance: Bool = true
}

fileprivate typealias boolVoidType = @convention(c) (AnyObject, Selector, Bool) -> Void
fileprivate typealias viewControllerVoidType = @convention(c) (AnyObject, Selector, UIViewController?) -> Void

// MARK: -

/// This UIViewController used for swizzling only. Not for instantiation.
public class UIViewControllerNotifications: UIViewController {

    // MARK: -

    private static var extendedProperties = [ObjectIdentifier: UIViewControllerExtendedProperties]()
    private static var extendedPropertiesUpdates: Int = 0

    /// The garbage collect threshold. This is useful for debugging.
    static var extendedPropertyGarbageCollectThreshold: Int = 200

    /// The count of the extended properties currently cached. This is useful for debugging.
    static var extendedPropertyCount: Int {
        return extendedProperties.count
    }

    private var extendedProperties: UIViewControllerExtendedProperties {
        // Check if we have properties already and that the propertier belong to us.
        // The `properties.imageView` may be nil since it's a weak reference and signals that the
        // `ObjectIdentifier` may have been reused.
        if let properties = Self.extendedProperties[ObjectIdentifier(self)], properties.viewController == self {
            return properties
        }
        Self.garbageCollectIfNeeded()
        let properties = UIViewControllerExtendedProperties()
        properties.viewController = self
        Self.extendedProperties[ObjectIdentifier(self)] = properties
        return properties
    }

    static func hasBeenDismissed(_ viewController: UIViewController) -> Bool {
        if let properties = Self.extendedProperties[ObjectIdentifier(viewController)],
            properties.viewController == viewController {
            return false
        }
        return true
    }

    static func garbageCollectIfNeeded() {
        extendedPropertiesUpdates += 1
        if extendedPropertiesUpdates < extendedPropertyGarbageCollectThreshold { return }
        extendedPropertiesUpdates = 0
        for (key, value) in Self.extendedProperties where value.viewController == nil {
            Self.extendedProperties[key] = nil
        }
    }

    // MARK: -

    private static var oldViewDidAppear: boolVoidType?

    public override func viewDidAppear(_ animated: Bool) {
        Self.oldViewDidAppear?(self, #selector(viewDidAppear(_:)), animated)
        NotificationCenter.default.post(name: UIViewControllerViewDidAppear, object: self)
        /*
        // Send the viewControllerDidPresent notification if needed:
        if self.extendedProperties.firstAppearance {
            if self.responds(to: #selector(viewControllerDidPresent)) {
                self.perform(#selector(viewControllerDidPresent))
            }
            // This Swift protocol check doesn't work consistently. Better to use Obj-C method checking.
            // if let presenter = self as? UIViewControllerPresenting {
            //    presenter.viewControllerDidPresent()
            // }
            NotificationCenter.default.post(name: UIViewControllerDidPresent, object: self)
            self.extendedProperties.firstAppearance = false
        }
        */
    }

    @objc func viewControllerDidPresent() {
    }

    // MARK: -

    private static func postDismissNotification(_ viewController: UIViewController) {
        guard !hasBeenDismissed(viewController) else { return }
        if viewController.responds(to: #selector(viewControllerDidDismiss)) {
            viewController.perform(#selector(viewControllerDidDismiss))
        }
        NotificationCenter.default.post(name: UIViewControllerDidDismiss, object: viewController)
        extendedProperties.removeValue(forKey: ObjectIdentifier(viewController))
    }

    @objc func viewControllerDidDismiss() {
    }

    private static func unwindAndPostDismissNotifications(_ viewController: UIViewController) {
        if let navigationController = (viewController as NSObject) as? UINavigationController {
            for vc in navigationController.viewControllers.reversed() {
                Self.postDismissNotification(vc)
            }
        }
        Self.postDismissNotification(viewController)
    }

    // MARK: -

    private static var oldViewDidDisappear: boolVoidType?

    public override func viewDidDisappear(_ animated: Bool) {
        Self.oldViewDidDisappear?(self, #selector(viewDidDisappear(_:)), animated)
        NotificationCenter.default.post(name: UIViewControllerViewDidDisappear, object: self)
        /*
        if self.isBeingDismissed {
            Self.unwindAndPostDismissNotifications(self)
        } else
        if self.parent == nil && !((self as UIViewController) is UITabBarController) {
            Self.unwindAndPostDismissNotifications(self)
        } else
        if let nav = self.navigationController, nav.isBeingDismissed {
            Self.unwindAndPostDismissNotifications(nav)
        }
        */
    }

    // MARK: -

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
