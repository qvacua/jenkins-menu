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

- (void)testDefaultProperties {
    assertThat(@(jenkins.state), is(@(JMJenkinsStateUnknown)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusUnknown)));
    assertThat(@(jenkins.interval), is(@300));
    assertThat(jenkins.jobs, isNot(nilValue()));
}

- (void)testKvoJenkinsUrl {
    jenkins.url = [NSURL URLWithString:@"http://some/url/to/jenkins"];

    assertThat(jenkins.xmlUrl, is([NSURL URLWithString:@"http://some/url/to/jenkins/api/xml"]));
}

- (void)testConnectionDidReceiveResponseFailure {
    NSHTTPURLResponse *response = mock([NSHTTPURLResponse class]);

    [given([response statusCode]) willReturnInteger:404];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.state), is(@(JMJenkinsStateHttpFailure)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@404));

    [given([response statusCode]) willReturnInteger:199];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.state), is(@(JMJenkinsStateHttpFailure)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@199));
}

- (void)testConnectionDidReceiveDataXmlError {
    NSHTTPURLResponse *response = mock([NSHTTPURLResponse class]);
    [given([response statusCode]) willReturnInteger:qHttpStatusOk];
    [jenkins connection:nil didReceiveResponse:response];

    [jenkins connection:nil didReceiveData:[@"<no xml<<<" dataUsingEncoding:NSUTF8StringEncoding]];
    assertThat(jenkins.jobs, is(empty()));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
    assertThat(@(jenkins.state), is(@(JMJenkinsStateXmlFailure)));
}

@end
