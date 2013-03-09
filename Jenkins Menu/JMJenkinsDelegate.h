#import <Foundation/Foundation.h>

@class JMJenkins;

@protocol JMJenkinsDelegate <NSObject>

- (void)jenkins:(JMJenkins *)jenkins serverTrustFailedwithHost:(NSString *)host;

@end
