/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef enum {
    JMJenkinsJobStateUnknown = 0,
    JMJenkinsJobStateGreen,
    JMJenkinsJobStateYellow,
    JMJenkinsJobStateRed,
    JMJenkinsJobStateAborted,
    JMJenkinsJobStateDisabled,
} JMJenkinsJobState;

@interface JMJenkinsJob : NSObject

@property NSString *name;
@property NSURL *url;
@property JMJenkinsJobState state;
@property JMJenkinsJobState lastState;
@property (getter=isRunning) BOOL running;

- (NSString *)description;

@end
