/**
 * Jenkins Menu
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import "NSMenuItem+Q.h"
#import <objc/runtime.h>

static char * const qBlockActionKey = "BlockActionKey";

@implementation NSMenuItem (Q)

- (void)setBlockAction:(void (^)(id))block {
    objc_setAssociatedObject(self, qBlockActionKey, nil, OBJC_ASSOCIATION_RETAIN);

    if (block == nil) {
        [self setTarget:nil];
        [self setAction:NULL];

        return;
    }

    objc_setAssociatedObject(self, qBlockActionKey, block, OBJC_ASSOCIATION_RETAIN);
    [self setTarget:self];
    [self setAction:@selector(blockActionWrapper:)];
}

- (void (^)(id))blockAction {
    return objc_getAssociatedObject(self, qBlockActionKey);
}

- (void)blockActionWrapper:(id)sender {
    void (^block)(id) = objc_getAssociatedObject(self, qBlockActionKey);

    block(sender);
}

@end
