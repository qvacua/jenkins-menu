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

@interface JMJenkinsTest : JMBaseTestCase
@end

@implementation JMJenkinsTest {
    JMJenkins *jenkins;
    NSHTTPURLResponse *response;
    NSData *xmlData;
}

- (void)setUp {
    [super setUp];

    jenkins = [[JMJenkins alloc] init];
    response = mock([NSHTTPURLResponse class]);

    NSURL *xmlUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"example-xml" withExtension:@"xml"];
    xmlData = [NSData dataWithContentsOfURL:xmlUrl];
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
    [self makeResponseReturnHttpOk];
    NSData *malformedXmlData = [@"<no xml<<<" dataUsingEncoding:NSUTF8StringEncoding];

    [jenkins connection:nil didReceiveData:malformedXmlData];
    assertThat(jenkins.jobs, is(empty()));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
    assertThat(@(jenkins.state), is(@(JMJenkinsStateXmlFailure)));
}

- (void)testConnectionDidReceiveDataEmptyXml {
    [self makeResponseReturnHttpOk];
    NSData *emptyXmlData = [@"<hudson></hudson>" dataUsingEncoding:NSUTF8StringEncoding];

    [jenkins connection:nil didReceiveData:emptyXmlData];
    assertThat(jenkins.jobs, is(empty()));
    assertThat(@(jenkins.lastHttpStatusCode), is(@(qHttpStatusOk)));
    assertThat(@(jenkins.state), is(@(JMJenkinsStateXmlFailure)));
}

- (void)testConnectionDidReceiveData {
    [self makeResponseReturnHttpOk];

    [jenkins connection:nil didReceiveData:xmlData];
    assertThat(jenkins.jobs, hasSize(8));
    assertThat(jenkins.viewUrl, is([NSURL URLWithString:@"http://ci.jruby.org/"]));

    [self assertJob:jenkins.jobs[0] name:@"activerecord-jdbc-master" urlString:@"http://ci.jruby.org/job/activerecord-jdbc-master/" state:JMJenkinsJobStateBlue running:NO];
    [self assertJob:jenkins.jobs[1] name:@"jruby-test-all-master" urlString:@"http://ci.jruby.org/job/jruby-test-all-master/" state:JMJenkinsJobStateBlue running:YES];
    [self assertJob:jenkins.jobs[2] name:@"jruby-rack-dist" urlString:@"http://ci.jruby.org/job/jruby-rack-dist/" state:JMJenkinsJobStateYellow running:NO];
    [self assertJob:jenkins.jobs[3] name:@"jruby-solaris" urlString:@"http://ci.jruby.org/job/jruby-solaris/" state:JMJenkinsJobStateYellow running:YES];
    [self assertJob:jenkins.jobs[4] name:@"jruby-spec-ci-master" urlString:@"http://ci.jruby.org/job/jruby-spec-ci-master/" state:JMJenkinsJobStateRed running:NO];
    [self assertJob:jenkins.jobs[5] name:@"jruby-ossl" urlString:@"http://ci.jruby.org/job/jruby-ossl/" state:JMJenkinsJobStateRed running:YES];
    [self assertJob:jenkins.jobs[6] name:@"jruby-test-master" urlString:@"http://ci.jruby.org/job/jruby-test-master/" state:JMJenkinsJobStateAborted running:NO];
    [self assertJob:jenkins.jobs[7] name:@"jruby-dist-release" urlString:@"http://ci.jruby.org/job/jruby-dist-release/" state:JMJenkinsJobStateDisabled running:NO];
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

@end
