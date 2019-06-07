//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The following notifications can be used if you need to track when TagCommander, comScore and NetMetrix 
 *  requests are made, and which information will be sent to these services, for unit testing purposes. 
 *
 *  These notifications are only emitted when enabling the `unitTesting` tracker configuration flag, @see
 *  `SRGAnalyticsConfiguration`.
 *
 *  Notifications may be received on background threads.
 */

// Notification sent when TagCommander analytics are sent.
OBJC_EXPORT NSString * const SRGAnalyticsRequestNotification;

// Information available for `SRGAnalyticsRequestNotification`.
OBJC_EXPORT NSString * const SRGAnalyticsLabelsKey;                         // Key for accessing the labels (as an `NSDictionary<NSString *, NSString *>`) available from the user info.

// Notification sent when a request is made to comScore.
OBJC_EXPORT NSString * const SRGAnalyticsComScoreRequestNotification;

// Information available for `SRGAnalyticsComScoreRequestNotification`.
OBJC_EXPORT NSString * const SRGAnalyticsComScoreLabelsKey;                 // Key for accessing the comScore labels (as an `NSDictionary<NSString *, NSString *>`) available from the user info.

// Notification sent when a request is made to NetMetrix.
OBJC_EXPORT NSString * const SRGAnalyticsNetmetrixRequestNotification;

// Information available for `SRGAnalyticsNetmetrixRequestNotification`.
OBJC_EXPORT NSString * const SRGAnalyticsNetmetrixURLKey;

/**
 *  Get the currrent unique identifier added to all measurements made in unit testing mode.
 */
OBJC_EXPORT NSString * _Nonnull SRGAnalyticsUnitTestingIdentifier(void);

/**
 *  Renew the unique identifier added to all measurements made in unit testing mode.
 *
 *  @discussion Renewal does not alter the unit test identifier of a playback session while still running.
 */
OBJC_EXPORT void SRGAnalyticsRenewUnitTestingIdentifier(void);

NS_ASSUME_NONNULL_END
