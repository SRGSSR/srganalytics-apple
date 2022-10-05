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
@property (nonatomic, copy) NSString *sourceKey;
@property (nonatomic, copy) NSString *siteName;

@end

@implementation SRGAnalyticsConfiguration

#pragma mark Object lifecycle

- (instancetype)initWithBusinessUnitIdentifier:(SRGAnalyticsBusinessUnitIdentifier)businessUnitIdentifier
                                     sourceKey:(NSString *)sourceKey
                                      siteName:(NSString *)siteName
{
    if (self = [super init] ) {
        self.businessUnitIdentifier = businessUnitIdentifier;
        self.sourceKey = sourceKey;
        self.siteName = siteName;
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

- (SRGAnalyticsEnvironment)environment
{
    switch (self.environmentMode) {
        case SRGAnalyticsEnvironmentModePreProduction: {
            return SRGAnalyticsEnvironmentPreProduction;
            break;
        }
            
        case SRGAnalyticsEnvironmentModeProduction: {
            return SRGAnalyticsEnvironmentProduction;
            break;
        }
        
        case SRGAnalyticsEnvironmentModeAutomatic:
        default: {
            return NSBundle.srg_isProductionVersion ? SRGAnalyticsEnvironmentProduction : SRGAnalyticsEnvironmentPreProduction;
            break;
        }
    }
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsConfiguration *configuration = [self.class allocWithZone:zone];
    configuration.businessUnitIdentifier = self.businessUnitIdentifier;
    configuration.sourceKey = self.sourceKey;
    configuration.siteName = self.siteName;
    configuration.centralized = self.centralized;
    configuration.environmentMode = self.environmentMode;
    configuration.unitTesting = self.unitTesting;
    return configuration;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; businessUnitIdentifier = %@; site = %@; sourceKey = %@; siteName = %@",
            self.class,
            self,
            self.businessUnitIdentifier,
            @(self.site),
            self.sourceKey,
            self.siteName];
}

@end
