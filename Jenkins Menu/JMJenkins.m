/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMJenkins.h"

@implementation JMJenkins {
    NSURL *_jenkinsXmlUrl;
    NSURL *_jenkinsUrl;

    NSTimeInterval _interval;

    BOOL _lastConnectionSuccessful;
}

@synthesize jenkinsXmlUrl = _jenkinsXmlUrl;
@synthesize jenkinsUrl = _jenkinsUrl;
@synthesize interval = _interval;
@synthesize lastConnectionSuccessful = _lastConnectionSuccessful;

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSInteger responseStatusCode = [httpResponse statusCode];

    if (responseStatusCode < HTTP_STATUS_OK || responseStatusCode >= HTTPS_STATUS_BAD_REQUEST) {
        NSLog(@"Connection was not successful. HTTP status code was: %ld", responseStatusCode);
        _lastConnectionSuccessful = NO;
    } else {
        _lastConnectionSuccessful = YES;
    }
}

//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
//    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    [self connection:connection willSendRequestForAuthenticationChallenge:challenge];
//}
//
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]
//            && [self shouldTrustHost:challenge.protectionSpace.host]) {
//        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//
//        return;
//    }
//
//    if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
//        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
//        return;
//    }
//
//    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
//}
//
//- (BOOL)shouldTrustHost:(NSString *)host {
//    if (_trustHost)
//        return YES;
//    NSArray *trustedHosts = [[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULT_TRUSTED_HOSTS_KEY];
//    return [trustedHosts containsObject:host];
//}

//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
//    NSLog(@"connection to %@ failed: %@", self.jenkinsXmlUrl, error);
//
//    if (error.code == -1202 && [self askWhetherToTrustHost:self.jenkinsXmlUrl.host]) {
//        _trustHost = YES;
//        [self makeRequest];
//    } else
//        [self showErrorStatus:error.localizedDescription];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    if (!_lastConnectionSuccessful) {
//        return;
//    }
//
//    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithData:data options:0 error:NULL];
//    NSArray *children = [[xmlDocument rootElement] children];
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
//}

@end
