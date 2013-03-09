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

- (id)init {
    self = [super init];
    if (self) {
        _interval = qDefaultInterval;
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

@end
