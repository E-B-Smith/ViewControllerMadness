import UIKit

public extension UIResponder {
    var viewController: UIViewController? {
        if let vc = self as? UIViewController { return vc }

        var object = self.next
        while (object != nil && object != self) {
            if let vc = object as? UIViewController {
                return vc
            }
            object = object?.next
        }
        return nil
    }
}

fileprivate typealias eventVoidType = @convention(c) (AnyObject, Selector, UIEvent) -> Void

class UIWindowEvents: UIWindow {

    public fileprivate(set) static weak var lastTouchView: UIView?

    private static var oldSendEvent: eventVoidType?

    override func sendEvent(_ event: UIEvent) {
        if let touch = event.allTouches?.randomElement(), let view = touch.view {
            Self.lastTouchView = view
        }
        Self.oldSendEvent?(self, #selector(sendEvent(_:)), event)
    }

    private static func typedSwizzle<T>(_ selector: Selector) -> T {
        let imp = swizzle(
            class: UIWindow.self,
            selector: selector,
            implementation: self.instanceMethod(for: selector)
        )
        return unsafeBitCast(imp, to: T.self)
    }

    /// Call this class method at app initialization to start the notifications.
    public static func startTracking() {
        oldSendEvent = typedSwizzle(#selector(sendEvent(_:)))
    }

}
