/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

static int const qHttpStatusOk = 200;
static int const qHttpsStatusBadRequest = 400;

@interface JMJenkins : NSObject <NSURLConnectionDelegate>

@property NSURL *url;
@property (readonly) NSURL *xmlUrl;
@property NSTimeInterval interval;

@end
