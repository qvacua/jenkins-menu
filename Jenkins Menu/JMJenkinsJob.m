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

@synthesize name = _name;
@synthesize url = _url;
@synthesize lastState = _lastState;
@synthesize running = _running;

- (JMJenkinsJobState)state {
    return _state;
}

- (void)setState:(JMJenkinsJobState)newState {
    self.lastState = self.state;
    _state = newState;
}

@end
