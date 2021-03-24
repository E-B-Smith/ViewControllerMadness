#import "Swizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>

// Function `objc_msgSendSuper2()` takes the current search class, not its superclass.
// Declared in https://opensource.apple.com/source/objc4/objc4-493.9/runtime/objc-abi.h
OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

_Nullable IMP pspdf_swizzleSelector(Class clazz, SEL selector, IMP newImplementation) {
    // Cannot swizzle methods that aren't implemented by the class or one of its parents.
    // If the method does not exist for this class, do nothing.
    const Method method = class_getInstanceMethod(clazz, selector);
    if (!method) {
        NSLog(@"Selector '%@' doesn't exist in '%@'.", NSStringFromSelector(selector), NSStringFromClass(clazz));
        return NULL;
    }

    // Make sure the class implements the method. If this is not the case, inject an implementation,
    // only calling 'super'.
    const char *types = method_getTypeEncoding(method);
    class_addMethod(clazz, selector, imp_implementationWithBlock(^(__unsafe_unretained id self, va_list argp) {
        struct objc_super super = {self, clazz};
        return ((id(*)(struct objc_super *, SEL, va_list))objc_msgSendSuper2)(&super, selector, argp);
    }), types);

    // Swizzle:
    return class_replaceMethod(clazz, selector, newImplementation, types);
}
