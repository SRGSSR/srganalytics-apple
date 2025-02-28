//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "NSString+SRGAnalytics.h"
#import "SRGAnalytics.h"
#import "SRGAnalyticsLabels+Private.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNotifications+Private.h"

@import ComScore;
@import TCCore;
@import TCServerSide_noIDFA;

static NSString * s_unitTestingIdentifier = nil;

__attribute__((constructor)) static void SRGAnalyticsTrackerInit(void)
{
    [TCDebug setDebugLevel:TCLogLevel_None];
}

NSString *SRGAnalyticsUnitTestingIdentifier(void)
{
    if (! s_unitTestingIdentifier) {
        SRGAnalyticsRenewUnitTestingIdentifier();
    }
    return s_unitTestingIdentifier;
}

void SRGAnalyticsRenewUnitTestingIdentifier(void)
{
    s_unitTestingIdentifier = NSUUID.UUID.UUIDString;
}

@interface SRGAnalyticsTracker ()

@property (nonatomic, copy) SRGAnalyticsConfiguration *configuration;
@property (nonatomic, weak) id<SRGAnalyticsTrackerDataSource> dataSource;

@property (nonatomic) ServerSide *serverSide;
@property (nonatomic) SCORStreamingAnalytics *streamSense;

@property (nonatomic) SRGAnalyticsLabels *globalLabels;

@property (nonatomic, readonly) NSDictionary *defaultComScoreLabels;
@property (nonatomic, readonly) NSDictionary *defaultLabels;

@end

@implementation SRGAnalyticsTracker

#pragma mark Class methods

+ (instancetype)sharedTracker
{
    static SRGAnalyticsTracker *s_sharedInstance = nil;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_sharedInstance = [SRGAnalyticsTracker new];
    });
    return s_sharedInstance;
}

#pragma mark Startup

- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration
{
    [self startWithConfiguration:configuration dataSource:nil];
}

- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration
                    dataSource:(id<SRGAnalyticsTrackerDataSource>)dataSource
{
    if (self.configuration) {
        SRGAnalyticsLogWarning(@"tracker", @"The tracker is already started");
        return;
    }
    
    self.configuration = configuration;
    self.dataSource = dataSource;

    if (configuration.unitTesting) {
        SRGAnalyticsEnableRequestInterceptor();
    }

    [self startComScoreWithConfiguration:configuration];
    [self startCommandersActWithConfiguration:configuration];
}

- (void)startComScoreWithConfiguration:(SRGAnalyticsConfiguration *)configuration
{
    SCORPublisherConfiguration *publisherConfiguration = [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder *builder) {
        builder.publisherId = @"6036016";
        builder.secureTransmissionEnabled = YES;
        builder.persistentLabels = [self persistentComScoreLabels];
        builder.startLabels = [self defaultComScoreLabels];

        // See https://confluence.srg.beecollaboration.com/display/INTFORSCHUNG/ComScore+-+Media+Metrix+Report
        // Coding Document for Video Players, page 16
        builder.httpRedirectCachingEnabled = NO;
    }];

    SCORConfiguration *comScoreConfiguration = [SCORAnalytics configuration];
    [comScoreConfiguration addClientWithConfiguration:publisherConfiguration];

    comScoreConfiguration.applicationVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    comScoreConfiguration.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundAndBackground;
    comScoreConfiguration.preventAdSupportUsage = YES;

    [SCORAnalytics start];
}

- (void)startCommandersActWithConfiguration:(SRGAnalyticsConfiguration *)configuration
{
    self.serverSide = [[ServerSide alloc] initWithSiteID:(int)configuration.site andSourceKey:configuration.sourceKey];
    [self.serverSide enableRunningInBackground];
    [self.serverSide waitForUserAgent];

    [self.serverSide addPermanentData:@"app_library_version" withValue:SRGAnalyticsMarketingVersion()];
    [self.serverSide addPermanentData:@"navigation_app_site_name" withValue:configuration.siteName];
    [self.serverSide addPermanentData:@"navigation_device" withValue:[self device]];

    // Use the legacy V4 identifier as unique identifier in V5.
    TCDevice.sharedInstance.sdkID = TCPredefinedVariables.sharedInstance.uniqueIdentifier;
    [TCPredefinedVariables.sharedInstance useLegacyUniqueIDForAnonymousID];
}

#pragma mark Labels

- (NSDictionary<NSString *, NSString *> *)persistentComScoreLabels
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    labels[@"mp_v"] = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    labels[@"mp_brand"] = self.configuration.businessUnitIdentifier.uppercaseString;
    return labels.copy;
}

- (NSDictionary<NSString *, NSString *> *)defaultComScoreLabels
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];

    NSDictionary<NSString *, NSString *> *globalLabels = self.globalLabels.comScoreLabelsDictionary;
    if (globalLabels) {
        [labels addEntriesFromDictionary:globalLabels];
    }

    NSDictionary<NSString *, NSString *> *dataSourceLabels = self.dataSource.srg_globalLabels.comScoreLabelsDictionary;
    if (dataSourceLabels) {
        [labels addEntriesFromDictionary:dataSourceLabels];
    }

    return labels.copy;
}

- (NSDictionary<NSString *, NSString *> *)defaultLabels
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];

    NSDictionary<NSString *, NSString *> *globalLabels = self.globalLabels.labelsDictionary;
    if (globalLabels) {
        [labels addEntriesFromDictionary:globalLabels];
    }

    NSDictionary<NSString *, NSString *> *dataSourceLabels = self.dataSourceLabels.labelsDictionary;
    if (dataSourceLabels) {
        [labels addEntriesFromDictionary:dataSourceLabels];
    }

    return labels.copy;
}

- (SRGAnalyticsLabels *)dataSourceLabels
{
    return self.dataSource.srg_globalLabels;
}

- (NSString *)pageIdWithTitle:(NSString *)title levels:(NSArray<NSString *> *)levels
{
    NSString *category = @"app";
    
    if (levels.count > 0) {
        __block NSMutableString *levelsComScoreFormattedString = [NSMutableString new];
        [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull level, NSUInteger idx, BOOL * _Nonnull stop) {
            if (levelsComScoreFormattedString.length > 0) {
                [levelsComScoreFormattedString appendString:@"."];
            }
            [levelsComScoreFormattedString appendString:level.srg_comScoreFormattedString];
        }];
        category = levelsComScoreFormattedString.copy;
    }
    
    return [NSString stringWithFormat:@"%@.%@", category, title.srg_comScoreFormattedString];
}

- (NSString *)device
{
    if ([self isMacCatalystApp] || [self isiOSAppOnMac]) {
        return @"desktop";
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"phone";
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return @"tablet";
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomTV) {
        return @"tvbox";
    }
    else {
        return @"phone";
    }
}

- (BOOL)isMacCatalystApp
{
    if (@available(iOS 13, tvOS 13, *)) {
        return NSProcessInfo.processInfo.isMacCatalystApp;
    }
    else {
        return NO;
    }
}

- (BOOL)isiOSAppOnMac
{
    if (@available(iOS 14, tvOS 14, *)) {
        return NSProcessInfo.processInfo.isiOSAppOnMac;
    }
    else {
        return NO;
    }
}

#pragma mark General event tracking (internal use only)

- (void)sendCommandersActPageViewEventWithTitle:(NSString *)title
                                           type:(NSString *)type
                                         labels:(NSDictionary<NSString *, NSString *> *)labels
{
    NSAssert(title.length != 0 && type.length != 0, @"A title and a type are required");

    TCPageViewEvent *event = [[TCPageViewEvent alloc] initWithType:type];
    event.pageName = title;
    [self.defaultLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [event addAdditionalProperty:key withStringValue:value];
    }];

    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [event addAdditionalProperty:key withStringValue:value];
    }];

    if (self.configuration.unitTesting) {
        [event addAdditionalProperty:@"srg_test_id" withStringValue:SRGAnalyticsUnitTestingIdentifier()];
    }

    [self.serverSide execute:event];
}

- (void)sendCommandersActCustomEventWithName:(NSString *)name
                                      labels:(NSDictionary<NSString *, NSString *> *)labels
{
    NSAssert(name.length != 0, @"A name is required");

    TCCustomEvent *event = [[TCCustomEvent alloc] initWithName:name];
    [self.defaultLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [event addAdditionalProperty:key withStringValue:value];
    }];

    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [event addAdditionalProperty:key withStringValue:value];
    }];

    if (self.configuration.unitTesting) {
        [event addAdditionalProperty:@"srg_test_id" withStringValue:SRGAnalyticsUnitTestingIdentifier()];
    }

    [self.serverSide execute:event];
}

#pragma mark Page view tracking

- (void)trackPageViewWithTitle:(NSString *)title
                          type:(NSString *)type
                        levels:(NSArray<NSString *> *)levels
{
    [self trackPageViewWithTitle:title type:type levels:levels labels:nil fromPushNotification:NO];
}

- (void)trackPageViewWithTitle:(NSString *)title
                          type:(NSString *)type
                        levels:(NSArray<NSString *> *)levels
                        labels:(SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
{
    [self trackPageViewWithTitle:title type:type levels:levels labels:labels fromPushNotification:fromPushNotification ignoreApplicationState:NO];
}

- (void)uncheckedTrackPageViewWithTitle:(NSString *)title
                                   type:(NSString *)type
                                 levels:(NSArray<NSString *> *)levels
{
    [self uncheckedTrackPageViewWithTitle:title type:type levels:levels labels:nil];
}

- (void)uncheckedTrackPageViewWithTitle:(NSString *)title
                                   type:(NSString *)type
                                 levels:(NSArray<NSString *> *)levels
                                 labels:(SRGAnalyticsPageViewLabels *)labels
{
    [self trackPageViewWithTitle:title type:type levels:levels labels:labels fromPushNotification:NO ignoreApplicationState:YES];
}

- (void)trackPageViewWithTitle:(NSString *)title
                          type:(NSString *)type
                        levels:(NSArray<NSString *> *)levels
                        labels:(SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
        ignoreApplicationState:(BOOL)ignoreApplicationState
{
    if (! self.configuration) {
        SRGAnalyticsLogWarning(@"tracker", @"The tracker has not been started yet");
        return;
    }
    
    if (title.length == 0 || type.length == 0 || (! ignoreApplicationState && UIApplication.sharedApplication.applicationState == UIApplicationStateBackground)) {
        return;
    }
    
    [self trackCommandersActPageViewWithTitle:title type:type levels:levels labels:labels fromPushNotification:fromPushNotification];
}

- (void)trackCommandersActPageViewWithTitle:(NSString *)title
                                       type:(NSString *)type
                                     levels:(NSArray<NSString *> *)levels
                                     labels:(SRGAnalyticsPageViewLabels *)labels
                       fromPushNotification:(BOOL)fromPushNotification
{
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetString:@"app" forKey:@"navigation_property_type"];
    [fullLabels srg_safelySetString:self.configuration.businessUnitIdentifier.uppercaseString forKey:@"content_bu_owner"];
    [fullLabels srg_safelySetString:fromPushNotification ? @"true" : @"false" forKey:@"accessed_after_push_notification"];

    [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 7) {
            *stop = YES;
            return;
        }

        NSString *levelKey = [NSString stringWithFormat:@"navigation_level_%@", @(idx + 1)];
        [fullLabels srg_safelySetString:object forKey:levelKey];
    }];

    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabels addEntriesFromDictionary:labelsDictionary];
    }

    if (self.configuration.unitTesting) {
        [fullLabels srg_safelySetString:SRGAnalyticsUnitTestingIdentifier() forKey:@"srg_test_id"];
    }

    [self sendCommandersActPageViewEventWithTitle:title type:type labels:fullLabels.copy];
}

#pragma mark Event tracking

- (void)trackEventWithName:(NSString *)name
{
    [self trackEventWithName:name labels:nil];
}

- (void)trackEventWithName:(NSString *)name
                    labels:(SRGAnalyticsEventLabels *)labels
{
    if (! self.configuration) {
        SRGAnalyticsLogWarning(@"tracker", @"The tracker has not been started yet");
        return;
    }
    
    if (name.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing name. No event will be sent");
        return;
    }
    
    [self trackCommandersActEventWithName:name labels:labels];
}

- (void)trackCommandersActEventWithName:(NSString *)name labels:(SRGAnalyticsEventLabels *)labels
{
    NSAssert(self.configuration != nil, @"The tracker must be started");

    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    
    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabels addEntriesFromDictionary:labelsDictionary];
    }

    if (self.configuration.unitTesting) {
        [fullLabels srg_safelySetString:SRGAnalyticsUnitTestingIdentifier() forKey:@"srg_test_id"];
    }

    [self sendCommandersActCustomEventWithName:name labels:fullLabels.copy];
}

#pragma mark Description

- (NSString *)description
{
    if (self.configuration) {
        return [NSString stringWithFormat:@"<%@: %p; configuration = %@>",
                self.class,
                self,
                self.configuration];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p (not started yet)>", self.class, self];
    }
}

@end
