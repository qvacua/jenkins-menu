/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMJenkins.h"
#import "JMJenkinsJob.h"
#import "JMJenkinsDelegate.h"
#import "JMTrustedHostManager.h"

static NSTimeInterval const qDefaultInterval = 5 * 60;

@interface JMJenkins ()
@property (readwrite) NSInteger lastHttpStatusCode;
@property (readwrite) NSInteger state;
@property (readwrite) NSURL *viewUrl;
@property (readonly) NSMutableArray *mutableJobs;
@property (readwrite) NSString *potentialHostToTrust;
@end

@implementation JMJenkins {
    NSMutableArray *_mutableJobs;
    NSString *_potentialHostToTrust;
}

@dynamic jobs;

@synthesize url = _url;
@synthesize xmlUrl = _xmlUrl;
@synthesize interval = _interval;
@synthesize state = _state;
@synthesize lastHttpStatusCode = _lastHttpStatusCode;
@synthesize viewUrl = _viewUrl;
@synthesize mutableJobs = _mutableJobs;
@synthesize delegate = _delegate;
@synthesize trustedHostManager = _trustedHostManager;
@synthesize potentialHostToTrust = _potentialHostToTrust;

#pragma mark Public
- (NSArray *)jobs {
    return self.mutableJobs;
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    if (self) {
        _interval = qDefaultInterval;
        _state = JMJenkinsStateUnknown;
        _lastHttpStatusCode = qHttpStatusUnknown;
        _mutableJobs = [[NSMutableArray alloc] init];
        [self addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionNew context:NULL];
    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (![keyPath isEqualToString:@"url"]) {
        return;
    }

    NSURL *newUrl = change[NSKeyValueChangeNewKey];
    _xmlUrl = [newUrl URLByAppendingPathComponent:@"api/xml"];
}

#pragma mark NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"response");
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

    NSInteger responseStatusCode = [httpResponse statusCode];
    self.lastHttpStatusCode = responseStatusCode;

    if (responseStatusCode < qHttpStatusOk || responseStatusCode >= qHttpStatusBadRequest) {
        NSLog(@"Connection to %@ was not successful. The Http status code was: %ld", self.xmlUrl, responseStatusCode);
        self.state = JMJenkinsStateHttpFailure;
    } else {
        self.state = JMJenkinsStateSuccessful;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"data");
    if (self.state != JMJenkinsStateSuccessful) {
        return;
    }

    NSXMLDocument *xmlDoc = [self xmlDocumentFromData:data];
    if (xmlDoc == nil) {
        self.state = JMJenkinsStateXmlFailure;
        return;
    }

    NSArray *children = [[xmlDoc rootElement] children];
    if ([children count] == 0) {
        NSLog(@"XML of %@ is empty.", self.xmlUrl);

        self.state = JMJenkinsStateXmlFailure;
        return;
    }

    [children enumerateObjectsUsingBlock:^(NSXMLNode *childNode, NSUInteger index, BOOL *stop) {
        if ([[childNode name] isEqualToString:@"primaryView"]) {
            self.viewUrl = [self viewUrlFromXmlNode:childNode];
            return;
        }

        if ([[childNode name] isEqualToString:@"job"]) {
            [self.mutableJobs addObject:[self jobsFromXmlNode:childNode]];
            return;
        }
    }];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    /**
    * When we get an authentication challenge from the server, this delegate method is called before
    * - connecion:didReceiveResponse:
    * - connecion:didReceiveData:
    */

    NSLog(@"challenge");
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self.trustedHostManager shouldTrustHost:challenge.protectionSpace.host]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];

            self.potentialHostToTrust = nil;

            return;
        }
    }

    self.potentialHostToTrust = challenge.protectionSpace.host;

    if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
        return;
    }

    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([error code] == NSURLErrorServerCertificateUntrusted) {
        NSLog(@"fail");
        self.state = JMJenkinsStateServerTrustFailure;
        [self.delegate jenkins:self serverTrustFailedwithHost:_potentialHostToTrust];
    }
}

#pragma mark Private
- (JMJenkinsJob *)jobsFromXmlNode:(NSXMLNode *)node {
    JMJenkinsJob *job = [[JMJenkinsJob alloc] init];

    [[node children] enumerateObjectsUsingBlock:^(id childNode, NSUInteger index, BOOL *stop) {
        NSString *nodeName = [childNode name];
        NSString *nodeStringValue = [childNode stringValue];

        if ([nodeName isEqualToString:@"name"]) {
            job.name = nodeStringValue;
            return;
        }

        if ([nodeName isEqualToString:@"url"]) {
            job.url = [NSURL URLWithString:nodeStringValue];
            return;
        }

        if ([nodeName isEqualToString:@"color"]) {
            job.state = [self jobStateFromColor:nodeStringValue];
            job.running = [self runningStateFromColor:nodeStringValue];
            return;
        }
    }];

    return job;
}

- (NSXMLDocument *)xmlDocumentFromData:(NSData *)xmlData {
    NSError *xmlError = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:&xmlError];

    if (xmlError) {
        NSLog(@"XML parsing of %@ failed: %@", self.xmlUrl, xmlError);
        return nil;
    }

    return xmlDoc;
}

- (NSURL *)viewUrlFromXmlNode:(NSXMLNode *)node {
    __block NSURL *viewUrl;
    [[node children] enumerateObjectsUsingBlock:^(id childNode, NSUInteger index, BOOL *stop) {
        if (![[childNode name] isEqualToString:@"url"]) {
            return;
        }

        viewUrl = [NSURL URLWithString:[childNode stringValue]];
        *stop = YES;
    }];

    return viewUrl;
}

- (JMJenkinsJobState)jobStateFromColor:(NSString *)color {
    if ([color hasPrefix:@"blue"]) {
        return JMJenkinsJobStateBlue;
    }

    if ([color hasPrefix:@"yellow"]) {
        return JMJenkinsJobStateYellow;
    }

    if ([color hasPrefix:@"red"]) {
        return JMJenkinsJobStateRed;
    }

    if ([color hasPrefix:@"aborted"]) {
        return JMJenkinsJobStateAborted;
    }

    if ([color hasPrefix:@"disabled"]) {
        return JMJenkinsJobStateDisabled;
    }

    return JMJenkinsJobStateUnknown;
}

- (BOOL)runningStateFromColor:(NSString *)color {
    if ([color hasSuffix:@"_anime"]) {
        return YES;
    }

    return NO;
}

@end
