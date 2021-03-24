import ObjectiveC.runtime
import ObjectiveC.message

#if false

/*
 NOTE: Because Swift doesn't support varidic functions the same way Obj-C does it's unlikely that
 a pure Swift Swizzle implementation is possible without some sort of creepy magic.

 Also, `objc_msgSendSuper2` isn't included in the run time headers for some reason.
*/

/// `objc_msgSendSuper2()` takes the current search class, not its superclass.
/// Declared in https://opensource.apple.com/source/objc4/objc4-493.9/runtime/objc-abi.h
///
/// OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

//public func objc_msgSendSuper2(_ ssuper: objc_super, _ op: Selector, _ parmeters: CVarArg) -> Any?

/**
 Swaps a obj-c based method for another method.

 - Warning: Does not work with large struct returns.
*/
func swift_swizzle(clazz: AnyClass, selector: Selector, implementation: IMP) -> IMP? {
    // If the method does not exist for this class, do nothing.
    guard let originalMethod: Method = class_getInstanceMethod(clazz, selector) else {
        Log(.error, "Selector '\(NSStringFromSelector(selector))' doesn't exist in class '\(NSStringFromClass(clazz))'.")
        return nil
    }

    /*
    var originalIMP: IMP? = nil
    let swizzledViewDidLoadBlock: @convention(block) (UIViewController) -> Void = { receiver in
        if let originalIMP = originalIMP {
            let castedIMP = unsafeBitCast(originalIMP, to: ViewDidLoadRef.self)
            castedIMP(receiver, viewDidLoadSelector)
        }

        if ViewDidLoadInjector.canInject(to: receiver, supportedClasses: supportedClasses) {
            injection(receiver)
        }
    }
    */

    // Make sure the class implements the method. If this is not the case, inject an implementation, only calling 'super'.
    let types: UnsafePointer<Int8>? = method_getTypeEncoding(originalMethod)
    class_addMethod(
        clazz,
        selector,
        imp_implementationWithBlock({ (_ sself: AnyObject, _ argp: va_list) -> Any? in
            var ssuper = objc_super(receiver: Unmanaged.passUnretained(sself), super_class: clazz)
            return objc_msgSendSuper2(&ssuper, selector, argp)
            //return ((id(*)(struct objc_super *, SEL, va_list))objc_msgSendSuper2)(&super, selector, argp);
        }),
        types
    )

    // Swizzle:
    return class_replaceMethod(clazz, selector, implementation, types)
}

#endif
