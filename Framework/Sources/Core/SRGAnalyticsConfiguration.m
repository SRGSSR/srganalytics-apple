//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"

#import "NSBundle+SRGAnalytics.h"

SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRSI = @"rsi";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTR = @"rtr";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTS = @"rts";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRF = @"srf";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRG = @"srg";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI = @"swi";

SRGAnalyticsEnvironment const SRGAnalyticsEnvironmentPreProduction = @"preprod";
SRGAnalyticsEnvironment const SRGAnalyticsEnvironmentProduction = @"prod";

@interface SRGAnalyticsConfiguration ()

@property (nonatomic, copy) SRGAnalyticsBusinessUnitIdentifier businessUnitIdentifier;
@property (nonatomic) NSInteger container;
@property (nonatomic, copy) NSString *comScoreVirtualSite;
@property (nonatomic, copy) NSString *netMetrixIdentifier;

@end

@implementation SRGAnalyticsConfiguration

#pragma mark Object lifecycle

- (instancetype)initWithBusinessUnitIdentifier:(SRGAnalyticsBusinessUnitIdentifier)businessUnitIdentifier
                                     container:(NSInteger)container
                           comScoreVirtualSite:(NSString *)comScoreVirtualSite
                           netMetrixIdentifier:(NSString *)netMetrixIdentifier
{
    if (self = [super init] ) {
        self.businessUnitIdentifier = businessUnitIdentifier;
        self.container = container;
        self.comScoreVirtualSite = comScoreVirtualSite;
        self.netMetrixIdentifier = netMetrixIdentifier;
        self.centralized = YES;
        self.environmentMode = SRGAnalyticsEnvironmentModeAutomatic;
    }
    return self;
}

#pragma mark Getters and setters

- (NSInteger)site
{
    static NSDictionary<SRGAnalyticsBusinessUnitIdentifier, NSNumber *> *s_sites = nil;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_sites = @{ SRGAnalyticsBusinessUnitIdentifierRSI : @3668,
                     SRGAnalyticsBusinessUnitIdentifierRTR : @3666,       // Under the SRG umbrella
                     SRGAnalyticsBusinessUnitIdentifierRTS : @3669,
                     SRGAnalyticsBusinessUnitIdentifierSRF : @3667,
                     SRGAnalyticsBusinessUnitIdentifierSRG : @3666,
                     SRGAnalyticsBusinessUnitIdentifierSWI : @3670 };
    });
    
    NSString *businessUnitIdentifier = self.centralized ? SRGAnalyticsBusinessUnitIdentifierSRG : self.businessUnitIdentifier;
    return s_sites[businessUnitIdentifier].integerValue;
}

- (NSString *)netMetrixDomain
{
    // HTTPs domains as documented here: https://srfmmz.atlassian.net/wiki/display/SRGPLAY/HTTPS+Transition
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSString *> *s_domains;
    dispatch_once(&s_onceToken, ^{
        s_domains = @{ SRGAnalyticsBusinessUnitIdentifierRSI : @"rsi-ssl",
                       SRGAnalyticsBusinessUnitIdentifierRTR : @"rtr-ssl",
                       SRGAnalyticsBusinessUnitIdentifierRTS : @"rts-ssl",
                       SRGAnalyticsBusinessUnitIdentifierSRF : @"sftv-ssl",
                       SRGAnalyticsBusinessUnitIdentifierSWI : @"sinf-ssl" };
    });
    return s_domains[self.businessUnitIdentifier];
}

- (SRGAnalyticsEnvironment)environment
{
    if (self.environmentMode == SRGAnalyticsEnvironmentModeAutomatic) {
        return NSBundle.srg_isProductionVersion ? SRGAnalyticsEnvironmentProduction : SRGAnalyticsEnvironmentPreProduction;
    }
    else if (self.environmentMode == SRGAnalyticsEnvironmentModeProduction) {
        return SRGAnalyticsEnvironmentProduction;
    }
    else {
        return SRGAnalyticsEnvironmentPreProduction;
    }
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsConfiguration *configuration = [self.class allocWithZone:zone];
    configuration.businessUnitIdentifier = self.businessUnitIdentifier;
    configuration.container = self.container;
    configuration.comScoreVirtualSite = self.comScoreVirtualSite;
    configuration.netMetrixIdentifier = self.netMetrixIdentifier;
    configuration.centralized = self.centralized;
    configuration.environmentMode = self.environmentMode;
    configuration.unitTesting = self.unitTesting;
    return configuration;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; businessUnitIdentifier = %@; site = %@; container = %@; comScoreVurtualSite = %@; netMetrixIdentifier = %@>",
            self.class,
            self,
            self.businessUnitIdentifier,
            @(self.site),
            @(self.container),
            self.comScoreVirtualSite,
            self.netMetrixIdentifier];
}

@end
