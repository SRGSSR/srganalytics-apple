//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsHiddenEventLabels.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLabels+Private.h"

@implementation SRGAnalyticsHiddenEventLabels

#pragma mark Getters and setters

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"event_type"];
    [dictionary srg_safelySetString:self.value forKey:@"event_value"];
    [dictionary srg_safelySetString:self.source forKey:@"event_source"];
    
    [dictionary srg_safelySetString:self.extraValue1 forKey:@"event_value_1"];
    [dictionary srg_safelySetString:self.extraValue2 forKey:@"event_value_2"];
    [dictionary srg_safelySetString:self.extraValue3 forKey:@"event_value_3"];
    [dictionary srg_safelySetString:self.extraValue4 forKey:@"event_value_4"];
    [dictionary srg_safelySetString:self.extraValue5 forKey:@"event_value_5"];
    
    [dictionary addEntriesFromDictionary:[super labelsDictionary]];
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"srg_evgroup"];
    [dictionary srg_safelySetString:self.value forKey:@"srg_evvalue"];
    [dictionary srg_safelySetString:self.source forKey:@"srg_evsource"];
    
    [dictionary addEntriesFromDictionary:[super comScoreLabelsDictionary]];
    return [dictionary copy];
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsHiddenEventLabels *labels = [super copyWithZone:zone];
    labels.type = self.type;
    labels.value = self.value;
    labels.source = self.source;
    
    labels.extraValue1 = self.extraValue1;
    labels.extraValue2 = self.extraValue2;
    labels.extraValue3 = self.extraValue3;
    labels.extraValue4 = self.extraValue4;
    labels.extraValue5 = self.extraValue5;
    
    return labels;
}

@end
