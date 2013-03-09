/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMJenkins.h"

static NSTimeInterval const qDefaultInterval = 5 * 60;

@interface JMJenkins ()
@property (readwrite) NSInteger lastHttpStatusCode;
@property (readwrite) NSInteger state;
@end

@implementation JMJenkins {
    NSMutableArray *_jobs;
}

@synthesize url = _url;
@synthesize xmlUrl = _xmlUrl;
@synthesize interval = _interval;
@synthesize state = _state;
@synthesize lastHttpStatusCode = _lastHttpStatusCode;
@synthesize jobs = _jobs;

#pragma mark NSObject
- (id)init {
    self = [super init];
    if (self) {
        _interval = qDefaultInterval;
        _state = JMJenkinsStateUnknown;
        _lastHttpStatusCode = qHttpStatusUnknown;
        _jobs = [[NSMutableArray alloc] init];
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
    if (self.state != JMJenkinsStateSuccessful) {
        return;
    }

    NSError *xmlError = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data options:0 error:&xmlError];

    if (xmlError) {
        NSLog(@"XML parsing of %@ failed: %@", self.xmlUrl, xmlError);
        self.state = JMJenkinsStateXmlFailure;

        return;
    }

//    NSArray *children = [[xmlDoc rootElement] children];
//
//    if ([children count] == 0) {
//        NSLog(@"The XML is empty!");
//
//        [self showErrorStatus:NSLocalizedString(@"ErrorEmptyXML", @"")];
//        return;
//    }
//
//    __block NSUInteger redCount = 0;
//    __block NSUInteger yellowCount = 0;
//
//    [children enumerateObjectsUsingBlock:^(NSXMLNode *childNode, NSUInteger index, BOOL *stop) {
//        if ([[childNode name] isEqualToString:@"primaryView"]) {
//            [self filterPrimaryViewUrlFromNode:childNode];
//            return;
//        }
//
//        if ([[childNode name] isEqualToString:@"job"]) {
//            [self filterJobFromNode:childNode redCount:&redCount yellowCount:&yellowCount];
//            return;
//        }
//    }];
//
//    [self setStatusWithRed:redCount yellow:yellowCount];
//    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusSuccess", @"")];
}

@end
