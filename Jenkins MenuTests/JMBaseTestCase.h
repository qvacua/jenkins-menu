/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <SenTestingKit/SenTestingKit.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define isYes is(@(YES))
#define isNo is(@(NO))

@interface JMBaseTestCase : SenTestCase

@end
