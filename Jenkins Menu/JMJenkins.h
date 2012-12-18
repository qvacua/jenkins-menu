/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

static int const HTTP_STATUS_OK = 200;
static int const HTTPS_STATUS_BAD_REQUEST = 400;

@interface JMJenkins : NSObject <NSURLConnectionDelegate>

@property NSURL *jenkinsXmlUrl;
@property NSURL *jenkinsUrl;
@property NSTimeInterval interval;

@property BOOL lastConnectionSuccessful;
@end
