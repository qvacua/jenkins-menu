/**
 * Jenkins Menu
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <OCHamcrest/HCBaseMatcher.h>
#import <objc/objc-api.h>

@interface ArgumentCaptor : HCBaseMatcher

@property (strong, readonly) id argument;

@end

OBJC_EXPORT ArgumentCaptor *argCaptor();
