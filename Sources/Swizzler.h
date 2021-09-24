#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Takes the current search class and dynamically looks up its superclass.

 <a href="https://opensource.apple.com/source/objc4/objc4-493.9/runtime/objc-abi.h">objc-abi.h</a>

 @param super   The class for which to send to search and send a message to the super class.
 @param op      The message selector.
 @param ...     The arguments to send to the selector.
 @return        Returns the result of the message send. Note: Large object return types are tricky.
*/
OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

/**
 Swaps a new function (defined as an IMP) for an existing IMP. The original IMP is returned.

 This can't be written in Swift since Swift lacks C-style variable argument support.

 Here are some great swizzling resources on the web:
 <a href="https://pspdfkit.com/blog/2019/swizzling-in-swift/">swizzling-in-swift</a>
 <a href="https://defagos.github.io/yet_another_article_about_method_swizzling/">yet_another_article_about_method_swizzling</a>

 @param  clazz              The class to swizzle.
 @param  selector           The selector to swizzle.
 @param  newImplementation  The new implementation function to install.
 @return                    Returns the original IMP.
*/
OBJC_EXPORT _Nullable IMP pspdf_swizzleSelector(Class clazz, SEL selector, IMP newImplementation)
    NS_SWIFT_NAME(swizzle(class:selector:implementation:));

NS_ASSUME_NONNULL_END
