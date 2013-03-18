/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMBaseTestCase.h"
#import "JMJenkins.h"
#import "JMJenkinsJob.h"
#import "JMTrustedHostManager.h"
#import "JMJenkinsDelegate.h"
#import "ArgumentCaptor.h"

@interface JMJenkinsTest : JMBaseTestCase
@end

@implementation JMJenkinsTest {
    JMJenkins *jenkins;
    NSHTTPURLResponse *response;
    JMTrustedHostManager *trustedHostManager;
    NSURLAuthenticationChallenge *challenge;
    NSURLProtectionSpace *protectionSpace;
    id <NSURLAuthenticationChallengeSender> sender;
    id <JMJenkinsDelegate> delegate;
}

- (void)setUp {
    [super setUp];

    trustedHostManager = mock([JMTrustedHostManager class]);
    delegate = mockProtocol(@protocol(JMJenkinsDelegate));

    jenkins = [[JMJenkins alloc] init];
    jenkins.trustedHostManager = trustedHostManager;
    jenkins.delegate = delegate;


    response = mock([NSHTTPURLResponse class]);
    challenge = mock([NSURLAuthenticationChallenge class]);
    protectionSpace = mock([NSURLProtectionSpace class]);
    sender = mockProtocol(@protocol(NSURLAuthenticationChallengeSender));

    [given([challenge protectionSpace]) willReturn:protectionSpace];
    [given([challenge sender]) willReturn:sender];
    [given([protectionSpace host]) willReturn:@"http://some.host"];
}

- (void)testTotalStateRedAndCount {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"example-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(@(jenkins.totalState), is(@(JMJenkinsTotalStateRed)));
    assertThat(@([jenkins countOfRedJobs]), is(@2));
}

- (void)testTotalStateYellowAndCount {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"yellow-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(@(jenkins.totalState), is(@(JMJenkinsTotalStateYellow)));
    assertThat(@([jenkins countOfYellowJobs]), is(@2));
}

- (void)testTotalStateGreenAndCount {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"green-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(@(jenkins.totalState), is(@(JMJenkinsTotalStateGreen)));
    assertThat(@([jenkins countOfGreenJobs]), is(@2));
}

- (void)testTotalStateUnknown {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"unknown-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(@(jenkins.totalState), is(@(JMJenkinsTotalStateUnknown)));
}

- (void)testUpdate {
    jenkins.url = [NSURL URLWithString:@"pro://some/crazy/"];
    [jenkins update];
}

- (void)testDefaultProperties {
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateUnknown)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusUnknown)));
    assertThat(@(jenkins.interval), is(@300));
    assertThat(jenkins.jobs, isNot(nilValue()));
}

- (void)testKvoJenkinsUrl {
    jenkins.url = [NSURL URLWithString:@"http://some/url/to/jenkins"];

    assertThat(jenkins.xmlUrl, is([NSURL URLWithString:@"http://some/url/to/jenkins/api/xml"]));
}

- (void)testConnectionDidReceiveResponseForbidden {
    STFail(@"implement");

    [given([response statusCode]) willReturnInteger:qHttpForbidden];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateHttpFailure)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@404));

    ArgumentCaptor *captor = argCaptor();
    [verify(delegate) jenkins:jenkins updateFailed:captor];
    NSDictionary *userInfo = captor.argument;

    assertThat(userInfo, hasKey(qJenkinsHttpResponseErrorKey));
    assertThat(userInfo, hasValue(@404));
}

- (void)testConnectionDidReceiveResponseFailure1 {
    [given([response statusCode]) willReturnInteger:404];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateHttpFailure)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@404));

    ArgumentCaptor *captor = argCaptor();
    [verify(delegate) jenkins:jenkins updateFailed:captor];
    NSDictionary *userInfo = captor.argument;

    assertThat(userInfo, hasKey(qJenkinsHttpResponseErrorKey));
    assertThat(userInfo, hasValue(@404));
}

- (void)testConnectionDidReceiveResponseFailure2 {
    [given([response statusCode]) willReturnInteger:199];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateHttpFailure)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@199));

    ArgumentCaptor *captor = argCaptor();
    [verify(delegate) jenkins:jenkins updateFailed:captor];
    NSDictionary *userInfo = captor.argument;

    assertThat(userInfo, hasKey(qJenkinsHttpResponseErrorKey));
    assertThat(userInfo, hasValue(@199));
}

- (void)testConnectionDidReceiveResponse {
    [given([response statusCode]) willReturnInteger:qHttpStatusOk];
    [jenkins connection:nil didReceiveResponse:response];
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateSuccessful)));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
}

- (void)testConnectionDidReceiveDataXmlError {
    [self makeResponseReturnHttpOk];
    NSData *malformedXmlData = [@"<no xml<<<" dataUsingEncoding:NSUTF8StringEncoding];

    [jenkins connection:nil didReceiveData:malformedXmlData];
    assertThat(jenkins.jobs, is(empty()));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateXmlFailure)));
}

- (void)testConnectionDidReceiveDataEmptyXml {
    [self makeResponseReturnHttpOk];
    NSData *emptyXmlData = [@"<hudson></hudson>" dataUsingEncoding:NSUTF8StringEncoding];

    [jenkins connection:nil didReceiveData:emptyXmlData];
    assertThat(jenkins.jobs, is(empty()));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateXmlFailure)));
}

- (void)testConnectionDidReceiveData {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"example-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(jenkins.jobs, hasSize(8));
    assertThat(jenkins.viewUrl, is([NSURL URLWithString:@"http://ci.jruby.org/"]));

    [self assertJob:jenkins.jobs[0] name:@"activerecord-jdbc-master" urlString:@"http://ci.jruby.org/job/activerecord-jdbc-master/" state:JMJenkinsJobStateGreen running:NO];
    [self assertJob:jenkins.jobs[1] name:@"jruby-test-all-master" urlString:@"http://ci.jruby.org/job/jruby-test-all-master/" state:JMJenkinsJobStateGreen running:YES];
    [self assertJob:jenkins.jobs[2] name:@"jruby-rack-dist" urlString:@"http://ci.jruby.org/job/jruby-rack-dist/" state:JMJenkinsJobStateYellow running:NO];
    [self assertJob:jenkins.jobs[3] name:@"jruby-solaris" urlString:@"http://ci.jruby.org/job/jruby-solaris/" state:JMJenkinsJobStateYellow running:YES];
    [self assertJob:jenkins.jobs[4] name:@"jruby-spec-ci-master" urlString:@"http://ci.jruby.org/job/jruby-spec-ci-master/" state:JMJenkinsJobStateRed running:NO];
    [self assertJob:jenkins.jobs[5] name:@"jruby-ossl" urlString:@"http://ci.jruby.org/job/jruby-ossl/" state:JMJenkinsJobStateRed running:YES];
    [self assertJob:jenkins.jobs[6] name:@"jruby-test-master" urlString:@"http://ci.jruby.org/job/jruby-test-master/" state:JMJenkinsJobStateAborted running:NO];
    [self assertJob:jenkins.jobs[7] name:@"jruby-dist-release" urlString:@"http://ci.jruby.org/job/jruby-dist-release/" state:JMJenkinsJobStateDisabled running:NO];

    [verify(delegate) jenkins:jenkins updateFinished:nil];
}

/**
* @bug
*/
- (void)testConnectionDidReceiveDataMultipleTimes {
    [self makeResponseReturnHttpOk];
    NSData *xmlData = [self xmlDataFromFileName:@"example-xml"];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(jenkins.jobs, hasSize(8));

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(jenkins.jobs, hasSize(8));
}

- (void)testConnectionAuthenticationFirstContact {
    [given([protectionSpace authenticationMethod]) willReturn:NSURLAuthenticationMethodServerTrust];
    [given([trustedHostManager shouldTrustHost:@"http://some.host"]) willReturnBool:NO];

    [jenkins connection:nil willSendRequestForAuthenticationChallenge:challenge];

    assertThat(jenkins.potentialHostToTrust, is(@"http://some.host"));
    [verify(sender) performDefaultHandlingForAuthenticationChallenge:challenge];
}

- (void)testConnectionAuthenticationWillTrust {
    [given([protectionSpace authenticationMethod]) willReturn:NSURLAuthenticationMethodServerTrust];
    [given([trustedHostManager shouldTrustHost:@"http://some.host"]) willReturnBool:YES];

    [jenkins connection:nil willSendRequestForAuthenticationChallenge:challenge];

    assertThat(jenkins.potentialHostToTrust, is(nilValue()));
    [verify(sender) useCredential:instanceOf([NSURLCredential class]) forAuthenticationChallenge:challenge];
}

- (void)testConnectionAuthenticationSomeOtherAuthMethod {
    [given([protectionSpace authenticationMethod]) willReturn:NSURLAuthenticationMethodNTLM];

    [jenkins connection:nil willSendRequestForAuthenticationChallenge:challenge];

    assertThat(jenkins.potentialHostToTrust, is(@"http://some.host"));
    [verify(sender) performDefaultHandlingForAuthenticationChallenge:challenge];
}

- (void)testConnectionDidFailWithTrustIssue {
    [given([protectionSpace authenticationMethod]) willReturn:NSURLAuthenticationMethodServerTrust];
    [given([trustedHostManager shouldTrustHost:@"http://some.host"]) willReturnBool:NO];

    NSError *error = mock([NSError class]);
    [given([error code]) willReturnUnsignedInteger:NSURLErrorServerCertificateUntrusted];

    // this will set the _potentialHostToTrust
    [jenkins connection:nil willSendRequestForAuthenticationChallenge:challenge];

    [jenkins connection:nil didFailWithError:error];
    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateServerTrustFailure)));
    [verify(delegate) jenkins:jenkins serverTrustFailedwithHost:@"http://some.host"];

    [verifyCount(delegate, never()) jenkins:jenkins updateFailed:nil];
}

- (void)testConnectionDidFailForUnknownReason {
    NSError *error = mock([NSError class]);
    [given([error code]) willReturnUnsignedInteger:NSURLErrorServerCertificateUntrusted + 1];

    [jenkins connection:nil didFailWithError:error];

    assertThat(@(jenkins.connectionState), is(@(JMJenkinsConnectionStateFailure)));
    [verify(delegate) jenkins:jenkins updateFailed:@{
            qJenkinsConnectionErrorKey: error
    }];
}

#pragma mark Private
- (void)assertJob:(JMJenkinsJob *)job name:(NSString *)name urlString:(NSString *)urlString state:(JMJenkinsJobState)state running:(BOOL)running {
    assertThat(job.name, is(name));
    assertThat(job.url, is([NSURL URLWithString:urlString]));
    assertThat(@(job.state), is(@(state)));
    assertThat(@(job.running), is(@(running)));
}

- (void)makeResponseReturnHttpOk {
    [given([response statusCode]) willReturnInteger:qHttpStatusOk];
    [jenkins connection:nil didReceiveResponse:response];
}

- (NSData *)xmlDataFromFileName:(NSString *)fileName {
    NSURL *xmlUrl = [[NSBundle bundleForClass:[self class]] URLForResource:fileName withExtension:@"xml"];
    return [NSData dataWithContentsOfURL:xmlUrl];
}

@end
