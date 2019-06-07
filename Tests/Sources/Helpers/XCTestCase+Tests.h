//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

@interface XCTestCase (Tests)

/**
 *  Replacement for the buggy `-expectationForSingleNotification:object:handler:`, catching notifications only once.
 *  See http://openradar.appspot.com/radar?id=4976563959365632.
 */
- (XCTestExpectation *)expectationForSingleNotification:(NSNotificationName)notificationName object:(nullable id)objectToObserve handler:(nullable XCNotificationExpectationHandler)handler;

/**
 *  Expectation for general page view event notifications.
 */
- (XCTestExpectation *)expectationForPageViewEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for general hidden event notifications.
 */
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for playback-related hidden event notifications.
 */
- (XCTestExpectation *)expectationForPlayerEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for general ComScore hidden event notifications.
 */
- (XCTestExpectation *)expectationForComScoreHiddenEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for playback-related ComScore hidden event notifications.
 */
- (XCTestExpectation *)expectationForComScorePlayerEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for view event notifications.
 */
- (XCTestExpectation *)expectationForViewEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for comScore view event notifications.
 */
- (XCTestExpectation *)expectationForComScoreViewEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation fulfilled after some given time interval (in seconds), calling the optionally provided handler. Can
 *  be useful for ensuring nothing unexpected occurs during some time
 */
- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(nullable void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
