/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMJenkins.h"

static NSTimeInterval const qDefaultInterval = 5 * 60;

@implementation JMJenkins {
}

@synthesize url = _url;
@synthesize xmlUrl = _xmlUrl;
@synthesize interval = _interval;
@synthesize state = _state;
@synthesize lastHttpStatusCode = _lastHttpStatusCode;

#pragma mark NSObject

- (id)init {
    self = [super init];
    if (self) {
        _interval = qDefaultInterval;
        _state = JMJenkinsStateUnknown;
        _lastHttpStatusCode = qHttpStatusUnknown;
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
        self.state = JMJenkinsStateFailure;
    } else {
        self.state = JMJenkinsStateSuccessful;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

}

@end
