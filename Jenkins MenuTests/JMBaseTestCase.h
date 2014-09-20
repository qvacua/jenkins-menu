/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <XCTest/XCTest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define hasSize(number) hasCount(equalToInt(number))
#define isYes is(@(YES))
#define isNo is(@(NO))

@interface JMBaseTestCase : XCTestCase

@end
