#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT _Nullable IMP pspdf_swizzleSelector(Class clazz, SEL selector, IMP newImplementation)
    NS_SWIFT_NAME(swizzle(class:selector:implementation:));

NS_ASSUME_NONNULL_END
