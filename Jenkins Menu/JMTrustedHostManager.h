#import <Foundation/Foundation.h>

@interface JMTrustedHostManager : NSObject

- (BOOL)shouldTrustHost:(NSString *)host;

@end
