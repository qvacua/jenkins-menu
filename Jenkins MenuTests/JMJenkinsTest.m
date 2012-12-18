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

- (void)testConnectionDidReceiveResponse {
    NSHTTPURLResponse *response = mock([NSHTTPURLResponse class]);

    [given([response statusCode]) willReturnInteger:404];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.lastConnectionSuccessful), isNo);

    [given([response statusCode]) willReturnInteger:101];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.lastConnectionSuccessful), isNo);
}

@end
