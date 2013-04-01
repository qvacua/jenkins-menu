/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMJenkinsJob.h"

@implementation JMJenkinsJob {
    JMJenkinsJobState _state;
}

@dynamic state;

- (JMJenkinsJobState)state {
    return _state;
}

- (void)setState:(JMJenkinsJobState)newState {
    self.lastState = self.state;
    _state = newState;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.state=%d", self.state];
    [description appendFormat:@", self.name=%@", self.name];
    [description appendFormat:@", self.url=%@", self.url];
    [description appendFormat:@", self.lastState=%d", self.lastState];
    [description appendFormat:@", self.running=%d", self.running];
    [description appendString:@">"];
    return description;
}


@end
