/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol JMJenkinsDelegate;
@class JMTrustedHostManager;
@class JMCredential;

typedef enum {
    JMJenkinsConnectionStateUnknown = 0,
    JMJenkinsConnectionStateSuccessful,
    JMJenkinsConnectionStateConnectionFailure,
    JMJenkinsConnectionStateForbidden,
    JMJenkinsConnectionStateNoCredential,
    JMJenkinsConnectionStateHttpFailure,
    JMJenkinsConnectionStateXmlFailure,
    JMJenkinsConnectionStateServerTrustFailure,
    JMJenkinsConnectionStateFailure,
} JMJenkinsState;

typedef enum {
    JMJenkinsTotalStateUnknown = 0,
    JMJenkinsTotalStateGreen,
    JMJenkinsTotalStateYellow,
    JMJenkinsTotalStateRed,
} JMJenkinsJobsTotalState;

static int const qHttpStatusUnknown = -1;
static int const qHttpStatusOk = 200;
static int const qHttpStatusBadRequest = 400;
static const int qHttpForbidden = 403;

static NSString *const qJenkinsConnectionErrorKey = @"ConnectionFailedErrorKey";
static NSString *const qJenkinsHttpResponseErrorKey = @"HttpResponseFailedErrorKey";

@interface JMJenkins : NSObject <NSURLConnectionDataDelegate>

@property NSURL *url;
@property (readonly) NSURL *xmlUrl;
@property (getter=isSecured) BOOL secured;
@property JMCredential *credential;
@property NSTimeInterval interval;
@property (readonly) NSInteger connectionState;
@property (readonly) NSInteger lastHttpStatusCode;
@property (readonly) NSURL *viewUrl;
@property (readonly) NSArray *jobs;
@property (readonly) NSString *potentialHostToTrust;

@property id <JMJenkinsDelegate> delegate;
@property JMTrustedHostManager *trustedHostManager;

- (void)update;
- (JMJenkinsJobsTotalState)totalState;

- (NSUInteger)countOfRedJobs;
- (NSUInteger)countOfYellowJobs;
- (NSUInteger)countOfGreenJobs;

@end
