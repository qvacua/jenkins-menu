/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@interface JMCredential : NSObject

@property NSURL *url;
@property NSString *username;
@property NSString *password;

- (id)initWithUrl:(NSURL *)url username:(NSString *)username password:(NSString *)password;

@end

@interface JMKeychainManager : NSObject

- (JMCredential *)credentialForUrl:(NSURL *)url;

@end
