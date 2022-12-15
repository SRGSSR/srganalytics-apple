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
#import "UIViewController+SRGAnalytics.h"

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

    [self sendApplicationList];
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

    [self.serverSide addPermanentData:@"app_library_version" withValue:SRGAnalyticsMarketingVersion()];
    [self.serverSide addPermanentData:@"navigation_app_site_name" withValue:configuration.siteName];
    [self.serverSide addPermanentData:@"navigation_device" withValue:[self device]];
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
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
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

#pragma mark General event tracking (internal use only)

- (void)sendCommandersActPageViewEventWithTitle:(NSString *)title
                                         labels:(NSDictionary<NSString *, NSString *> *)labels
{
    NSAssert(title.length != 0, @"A title is required");

    TCPageViewEvent *event = [[TCPageViewEvent alloc] initWithType:title];
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
    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [event addAdditionalProperty:key withStringValue:value];
    }];

    if (self.configuration.unitTesting) {
        [event addAdditionalProperty:@"srg_test_id" withStringValue:SRGAnalyticsUnitTestingIdentifier()];
    }

    [self.serverSide execute:event];
}

#pragma mark Page view tracking

- (void)trackPageViewWithTitle:(NSString *)title levels:(NSArray<NSString *> *)levels
{
    [self trackPageViewWithTitle:title levels:levels labels:nil fromPushNotification:NO];
}

- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(NSArray<NSString *> *)levels
                        labels:(SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
{
    [self trackPageViewWithTitle:title levels:levels labels:labels fromPushNotification:fromPushNotification ignoreApplicationState:NO];
}

- (void)uncheckedTrackPageViewWithTitle:(NSString *)title levels:(NSArray<NSString *> *)levels
{
    [self uncheckedTrackPageViewWithTitle:title levels:levels labels:nil];
}

- (void)uncheckedTrackPageViewWithTitle:(NSString *)title
                                 levels:(NSArray<NSString *> *)levels
                                 labels:(SRGAnalyticsPageViewLabels *)labels
{
    [self trackPageViewWithTitle:title levels:levels labels:labels fromPushNotification:NO ignoreApplicationState:YES];
}

- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(NSArray<NSString *> *)levels
                        labels:(SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
        ignoreApplicationState:(BOOL)ignoreApplicationState
{
    if (! self.configuration) {
        SRGAnalyticsLogWarning(@"tracker", @"The tracker has not been started yet");
        return;
    }
    
    if (title.length == 0 || (! ignoreApplicationState && UIApplication.sharedApplication.applicationState == UIApplicationStateBackground)) {
        return;
    }
    
    [self trackCommandersActPageViewWithTitle:title levels:levels labels:labels fromPushNotification:fromPushNotification];
    [self trackComScorePageViewWithTitle:title levels:levels labels:labels fromPushNotification:fromPushNotification];
}

- (void)trackComScorePageViewWithTitle:(NSString *)title
                                levels:(NSArray<NSString *> *)levels
                                labels:(SRGAnalyticsPageViewLabels *)labels
                  fromPushNotification:(BOOL)fromPushNotification
{
    NSAssert(title.length != 0, @"A title is required");
    
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [self defaultComScoreLabels].mutableCopy;
    [fullLabels srg_safelySetString:title forKey:@"srg_title"];
    [fullLabels srg_safelySetString:@(fromPushNotification).stringValue forKey:@"srg_ap_push"];
    
    NSString *category = @"app";
    
    if (! levels) {
        [fullLabels srg_safelySetString:category forKey:@"srg_n1"];
    }
    else if (levels.count > 0) {
        __block NSMutableString *levelsComScoreFormattedString = [NSMutableString new];
        [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *levelKey = [NSString stringWithFormat:@"srg_n%@", @(idx + 1)];
            NSString *levelValue = [object description];
            
            if (idx < 10) {
                [fullLabels srg_safelySetString:levelValue forKey:levelKey];
            }
            
            if (levelsComScoreFormattedString.length > 0) {
                [levelsComScoreFormattedString appendString:@"."];
            }
            [levelsComScoreFormattedString appendString:levelValue.srg_comScoreFormattedString];
        }];
        
        category = levelsComScoreFormattedString.copy;
    }
    
    [fullLabels srg_safelySetString:category forKey:@"ns_category"];
    [fullLabels srg_safelySetString:[self pageIdWithTitle:title levels:levels] forKey:@"name"];
    
    NSDictionary<NSString *, NSString *> *comScoreLabelsDictionary = [labels comScoreLabelsDictionary];
    if (comScoreLabelsDictionary) {
        [fullLabels addEntriesFromDictionary:comScoreLabelsDictionary];
    }
    
    if (self.configuration.unitTesting) {
        [fullLabels srg_safelySetString:SRGAnalyticsUnitTestingIdentifier() forKey:@"srg_test_id"];
    }
    
    [SCORAnalytics notifyViewEventWithLabels:fullLabels.copy];
}

- (void)trackCommandersActPageViewWithTitle:(NSString *)title
                                     levels:(NSArray<NSString *> *)levels
                                     labels:(SRGAnalyticsPageViewLabels *)labels
                       fromPushNotification:(BOOL)fromPushNotification
{
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetString:@"app" forKey:@"navigation_property_type"];
    [fullLabels srg_safelySetString:self.configuration.businessUnitIdentifier.uppercaseString forKey:@"navigation_bu_distributer"];
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

    [self sendCommandersActPageViewEventWithTitle:title labels:fullLabels.copy];
}

#pragma mark Hidden event tracking

- (void)trackHiddenEventWithName:(NSString *)name
{
    [self trackHiddenEventWithName:name labels:nil];
}

- (void)trackHiddenEventWithName:(NSString *)name
                          labels:(SRGAnalyticsHiddenEventLabels *)labels
{
    if (! self.configuration) {
        SRGAnalyticsLogWarning(@"tracker", @"The tracker has not been started yet");
        return;
    }
    
    if (name.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing name. No event will be sent");
        return;
    }
    
    [self trackCommandersActHiddenEventWithName:name labels:labels];
}

- (void)trackCommandersActHiddenEventWithName:(NSString *)name labels:(SRGAnalyticsHiddenEventLabels *)labels
{
    NSAssert(self.configuration != nil, @"The tracker must be started");

    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetString:name forKey:@"event_name"];

    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabels addEntriesFromDictionary:labelsDictionary];
    }

    if (self.configuration.unitTesting) {
        [fullLabels srg_safelySetString:SRGAnalyticsUnitTestingIdentifier() forKey:@"srg_test_id"];
    }

    [self sendCommandersActCustomEventWithName:@"hidden_event" labels:fullLabels.copy];
}

#pragma mark Application list measurement

- (void)sendApplicationList
{
    // Tracks which SRG SSR applications are installed on the user device
    //
    // Specifications are available at: https://confluence.srg.beecollaboration.com/display/INTFORSCHUNG/App+Overlapping+Measurement
    //
    // This measurement is not critical and is therefore performed only once the tracker starts. If it fails for some reason
    // (no network, for example), the measurement will be attempted again the next time the application is started
    NSURL *applicationListURL = [NSURL URLWithString:@"https://pastebin.com/raw/RnZYEWCA"];
    [[[NSURLSession sharedSession] dataTaskWithURL:applicationListURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SRGAnalyticsLogError(@"tracker", @"The application list could not be retrieved. Reason: %@", error);
            return;
        }
        
        NSError *parseError = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (! JSONObject || ! [JSONObject isKindOfClass:NSArray.class]) {
            SRGAnalyticsLogError(@"tracker", @"The application list format is incorrect");
            return;
        }
        NSArray<NSDictionary *> *applicationDictionaries = JSONObject;
        
        // -canOpenURL: should only be called from the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Extract URL schemes and installed applications
            NSMutableSet<NSString *> *URLSchemes = [NSMutableSet set];
            NSMutableSet<NSString *> *installedApplications = [NSMutableSet set];
            for (NSDictionary *applicationDictionary in applicationDictionaries) {
                NSString *application = applicationDictionary[@"code"];
                NSString *URLScheme = applicationDictionary[@"ios"];
                
                if (URLScheme.length == 0 || ! application) {
                    SRGAnalyticsLogInfo(@"tracker", @"URL scheme or application name missing in %@. Skipped", applicationDictionary);
                    continue;
                }
                
                [URLSchemes addObject:URLScheme];
                
                NSString *URLString = [NSString stringWithFormat:@"%@://probe-for-srganalytics", URLScheme];
                if (! [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:URLString]]) {
                    continue;
                }
                
                [installedApplications addObject:application];
            }
            
            // To be able to open a URL in another application (and thus to be able to test for URL scheme support),
            // the application must declare the schemes it supports via its Info.plist file (under the
            // `LSApplicationQueriesSchemes` key). Check that the app list is consistent with the remote list, and
            // log an error if this is not the case.
            NSArray<NSString *> *declaredURLSchemesArray = NSBundle.mainBundle.infoDictionary[@"LSApplicationQueriesSchemes"];
            NSSet<NSString *> *declaredURLSchemes = declaredURLSchemesArray ? [NSSet setWithArray:declaredURLSchemesArray] : [NSSet set];
            if (! [URLSchemes isSubsetOfSet:declaredURLSchemes]) {
                SRGAnalyticsLogError(@"tracker", @"The URL schemes declared in your application Info.plist file under the "
                                     "'LSApplicationQueriesSchemes' key must at least contain the scheme list available at "
                                     "https://pastebin.com/raw/RnZYEWCA (the schemes are found under the 'ios' key, or "
                                     "a script is available in the SRGAnalytics repository to extract them). Please "
                                     "update your Info.plist file accordingly to make this message disappear.");
            }
            
            NSArray<NSString *> *sortedInstalledApplications = [installedApplications.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.type = @"hidden";
            labels.source = @"SRGAnalytics";
            labels.value = [sortedInstalledApplications componentsJoinedByString:@";"];
            
            [self trackHiddenEventWithName:@"Installed Apps" labels:labels];
        });
    }] resume];
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
