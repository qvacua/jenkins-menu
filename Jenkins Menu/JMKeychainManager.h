/**
 * Jenkins Menu
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@interface JMCredential : NSObject

@property NSString *username;
@property NSString *password;

- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end

@interface JMKeychainManager : NSObject

@property (readonly) NSString *lastErrorMessage;

- (JMCredential *)credentialForUrl:(NSURL *)url;
- (BOOL)storeCredential:(JMCredential *)credential forUrl:(NSURL *)url;

@end
