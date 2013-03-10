/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>

@interface NSMenuItem (Q)

- (void)setBlockAction:(void (^)(id sender))block;
- (void (^)(id))blockAction;

@end
