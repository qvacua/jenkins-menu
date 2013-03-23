/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@class JMJenkins;

@protocol JMJenkinsDelegate <NSObject>

@required
/**
* Called when the SSL certificate of the server cannot be trusted. Using this delegate method, you can ask the user
* whether to trust the server.
*
* @param host   the host of the server which could not be trusted
*/
- (void)jenkins:(JMJenkins *)jenkins serverTrustFailedwithHost:(NSString *)host;

/**
* Called when the update failed.
*
* @param userInfo   a dictionary containing info about the error occurred.
*/
- (void)jenkins:(JMJenkins *)jenkins updateFailed:(NSDictionary *)userInfo;

/**
* Only called when both the request and the parsing were successful.
*
* @param userInfo   yet always nil
*/
- (void)jenkins:(JMJenkins *)jenkins updateFinished:(NSDictionary *)userInfo;

/**
* Called directly after the request was created.
*
* @param userInfo   yet always nil
*/
- (void)jenkins:(JMJenkins *)jenkins updateStarted:(NSDictionary *)userInfo;

/**
* Called when the Jenkins instance is secured.
*
* @param userInfo   yet always nil
*/
- (void)jenkins:(JMJenkins *)jenkins forbidden:(id)userInfo;

- (void)jenkins:(JMJenkins *)jenkins wrongCredential:(NSDictionary *)userInfo;

@end
