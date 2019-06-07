//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Supported business units
 */
typedef NSString * SRGAnalyticsBusinessUnitIdentifier NS_TYPED_ENUM;

OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRSI;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTR;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTS;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRF;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRG;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI;

@interface SRGAnalyticsConfiguration : NSObject <NSCopying>

/**
 *  Create a measurement configuration. Check with the team responsible for measurements of your application to get 
 *  the correct settings to use for your application.
 *
 *  @param businessUnitIdentifier The identifier of the business unit which measurements are made for. Usually the
 *                                business unit which publishes the application.
 *  @param container              The TagCommander container identifier to which measurements will be sent.
 *  @param comScoreVirtualSite    The comScore virtual site to which measurements must be sent.
 *  @param netMetrixIdentifier    The NetMetrix application identifier to send measurements for.
 */
- (instancetype)initWithBusinessUnitIdentifier:(SRGAnalyticsBusinessUnitIdentifier)businessUnitIdentifier
                                     container:(NSInteger)container
                           comScoreVirtualSite:(NSString *)comScoreVirtualSite
                           netMetrixIdentifier:(NSString *)netMetrixIdentifier;

/**
 *  Set to `YES` if measurements are studied by the General SRG SSR Direction, or to `NO` if the business
 *  unit itself will perform the studies.
 *
 *  Default value is `YES`.
 */
@property (nonatomic, getter=isCentralized) BOOL centralized;

/**
 *  When set to `YES`, notifications will be emitted when analytics measurements are sent (@see `SRGAnalyticsNotifications.h`).
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isUnitTesting) BOOL unitTesting;

/**
 *  The SRG SSR business unit which measurements are associated with.
 */
@property (nonatomic, readonly, copy) SRGAnalyticsBusinessUnitIdentifier businessUnitIdentifier;

/**
 *  The TagCommander site.
 */
@property (nonatomic, readonly) NSInteger site;

/**
 *  The TagCommander container identifier.
 */
@property (nonatomic, readonly) NSInteger container;

/**
 *  The comScore virtual site to which measurements must be sent. By default `business_unit-app-test-v`.
 */
@property (nonatomic, readonly, copy) NSString *comScoreVirtualSite;

/**
 *  The NetMetrix domain.
 */
@property (nonatomic, readonly, copy, nullable) NSString *netMetrixDomain;

/**
 *  The NetMetrix application identifier.
 */
@property (nonatomic, readonly, copy) NSString *netMetrixIdentifier;

@end

@interface SRGAnalyticsConfiguration (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
