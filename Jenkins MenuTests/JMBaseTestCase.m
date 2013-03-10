/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMBaseTestCase.h"
#import <objc/runtime.h>

@implementation JMBaseTestCase {
    Method _originalMethod;
    IMP _originalImpl;
}

- (void)swapImplOfClass:(Class)clazz selector:(SEL)originalSelector withSelector:(SEL)newSelector {
    Method testMethod = class_getInstanceMethod([self class], newSelector);
    IMP testImpl = method_getImplementation(testMethod);

    _originalMethod = class_getClassMethod(clazz, originalSelector);
    _originalImpl = method_setImplementation(_originalMethod, testImpl);
}

@end
