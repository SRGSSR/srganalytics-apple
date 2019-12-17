//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

@implementation SRGAnalyticsLabels

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    if (self.customInfo) {
        [dictionary addEntriesFromDictionary:self.customInfo];
    }
    
    return dictionary.copy;
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    if (self.comScoreCustomInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreCustomInfo];
    }
    
    return dictionary.copy;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsLabels *labels = [[self.class allocWithZone:zone] init];
    labels.customInfo = self.customInfo;
    labels.comScoreCustomInfo = self.comScoreCustomInfo;
    return labels;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    SRGAnalyticsLabels *otherLabels = object;
    return [[self labelsDictionary] isEqual:[otherLabels labelsDictionary]]
        && [[self comScoreLabelsDictionary] isEqual:[otherLabels comScoreLabelsDictionary]];
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@", @([self labelsDictionary].hash), @([self comScoreLabelsDictionary].hash)].hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; labelsDictionary = %@; comScoreLabelsDictionary = %@>",
            self.class,
            self,
            self.labelsDictionary,
            self.comScoreLabelsDictionary];
}

@end
