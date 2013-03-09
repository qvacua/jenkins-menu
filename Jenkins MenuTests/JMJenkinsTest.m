/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMBaseTestCase.h"
#import "JMJenkins.h"

@interface JMJenkinsTest : JMBaseTestCase @end

@implementation JMJenkinsTest {
    JMJenkins *jenkins;
}

- (void)setUp {
    [super setUp];

    jenkins = [[JMJenkins alloc] init];
}

- (void)testDefaultInterval {
    assertThat(@(jenkins.interval), is(@300));
}

- (void)testKvoJenkinsUrl {
    jenkins.url = [NSURL URLWithString:@"http://some/url/to/jenkins"];

    assertThat(jenkins.xmlUrl, is([NSURL URLWithString:@"http://some/url/to/jenkins/api/xml"]));
}

@end
