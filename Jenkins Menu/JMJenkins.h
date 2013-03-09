/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef enum {
    JMJenkinsStateUnknown = 0,
    JMJenkinsStateSuccessful,
    JMJenkinsStateHttpFailure,
    JMJenkinsStateXmlFailure,
} JMJenkinsState;

static int const qHttpStatusUnknown = -1;
static int const qHttpStatusOk = 200;
static int const qHttpStatusBadRequest = 400;

@interface JMJenkins : NSObject <NSURLConnectionDataDelegate>

@property NSURL *url;
@property (readonly) NSURL *xmlUrl;
@property NSTimeInterval interval;
@property (readonly) NSInteger state;
@property (readonly) NSInteger lastHttpStatusCode;
@property (readonly) NSArray *jobs;

@end
