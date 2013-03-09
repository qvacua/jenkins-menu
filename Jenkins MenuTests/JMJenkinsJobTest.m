/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMBaseTestCase.h"
#import "JMJenkinsJob.h"

@interface JMJenkinsJobTest : JMBaseTestCase
@end

@implementation JMJenkinsJobTest {
    JMJenkinsJob *job;
}

- (void)setUp {
    [super setUp];

    job = [[JMJenkinsJob alloc] init];
}

- (void)testDefaultStates {
    assertThat(@(job.state), is(@(JMJenkinsJobStateUnknown)));
    assertThat(@(job.lastState), is(@(JMJenkinsJobStateUnknown)));
}

- (void)testSetState {
    job.state = JMJenkinsJobStateBlue;
    assertThat(@(job.state), is(@(JMJenkinsJobStateBlue)));
    assertThat(@(job.lastState), is(@(JMJenkinsJobStateUnknown)));

    job.state = JMJenkinsJobStateRed;
    assertThat(@(job.state), is(@(JMJenkinsJobStateRed)));
    assertThat(@(job.lastState), is(@(JMJenkinsJobStateBlue)));
}

@end
