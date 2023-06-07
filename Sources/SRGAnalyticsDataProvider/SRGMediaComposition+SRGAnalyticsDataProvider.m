//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition+SRGAnalyticsDataProvider.h"

#import "SRGResource+SRGAnalyticsDataProvider.h"
#import "SRGSegment+SRGAnalyticsDataProvider.h"

@import libextobjc;

@implementation SRGMediaComposition (SRGAnalyticsDataProvider)

- (SRGAnalyticsStreamLabels *)analyticsLabelsForResource:(SRGResource *)resource sourceUid:(NSString *)sourceUid
{
    NSAssert([self.mainChapter.resources containsObject:resource], @"The specified resource must be associated with the current context");
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    
    NSDictionary<NSString *, NSString *> *mainChapterLabels = self.mainChapter.analyticsLabels;
    if (mainChapterLabels.count != 0) {
        NSMutableDictionary<NSString *, NSString *> *customInfo = [NSMutableDictionary dictionary];
        if (self.analyticsLabels) {
            [customInfo addEntriesFromDictionary:self.analyticsLabels];
        }
        [customInfo addEntriesFromDictionary:mainChapterLabels];
        if (resource.analyticsLabels) {
            [customInfo addEntriesFromDictionary:resource.analyticsLabels];
        }
        customInfo[@"source_id"] = sourceUid;
        labels.customInfo = customInfo.copy;
    }
    
    NSDictionary<NSString *, NSString *> *mainChapterComScoreLabels = self.mainChapter.comScoreAnalyticsLabels;
    if (mainChapterComScoreLabels.count != 0) {
        NSMutableDictionary<NSString *, NSString *> *comScoreCustomInfo = [NSMutableDictionary dictionary];
        if (self.comScoreAnalyticsLabels) {
            [comScoreCustomInfo addEntriesFromDictionary:self.comScoreAnalyticsLabels];
        }
        [comScoreCustomInfo addEntriesFromDictionary:mainChapterComScoreLabels];
        if (resource.comScoreAnalyticsLabels) {
            [comScoreCustomInfo addEntriesFromDictionary:resource.comScoreAnalyticsLabels];
        }
        labels.comScoreCustomInfo = comScoreCustomInfo.copy;
    }
    
    return labels;
}

- (BOOL)playbackContextWithPreferredSettings:(SRGPlaybackSettings *)preferredSettings
                                contextBlock:(NS_NOESCAPE SRGPlaybackContextBlock)contextBlock
{
    if (! preferredSettings) {
        preferredSettings = [[SRGPlaybackSettings alloc] init];
    }
    
    SRGChapter *chapter = self.mainChapter;
    
    SRGStreamingMethod streamingMethod = preferredSettings.streamingMethod;
    if (streamingMethod == SRGStreamingMethodNone) {
        streamingMethod = chapter.recommendedStreamingMethod;
    }
    
    NSArray<SRGResource *> *resources = [chapter resourcesForStreamingMethod:streamingMethod];
    if (resources.count == 0) {
        resources = [chapter resourcesForStreamingMethod:chapter.recommendedStreamingMethod];
    }
    
    NSSortDescriptor *URLSchemeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, URL) ascending:NO comparator:^NSComparisonResult(NSURL * _Nonnull URL1, NSURL * _Nonnull URL2) {
        // Only declare ordering for important URL schemes. For other schemes the initial order will be preserved
        NSArray<NSString *> *orderedURLSchemes = @[@"http", @"https"];
        
        NSUInteger index1 = [orderedURLSchemes indexOfObject:URL1.scheme];
        NSUInteger index2 = [orderedURLSchemes indexOfObject:URL2.scheme];
        if (index1 == index2) {
            return NSOrderedSame;
        }
        // Unknown scheme < known scheme
        else if (index1 == NSNotFound) {
            return NSOrderedAscending;
        }
        // Known scheme > unknown scheme
        else if (index2 == NSNotFound) {
            return NSOrderedDescending;
        }
        else if (index1 < index2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    
    // Determine the stream type order to use (start with a default setup, overridden if a preferred value has been set).
    NSArray<NSNumber *> *orderedStreamTypes = @[@(SRGStreamTypeOnDemand), @(SRGStreamTypeLive), @(SRGStreamTypeDVR)];
    SRGStreamType streamType = preferredSettings.streamType;
    if (streamType != SRGStreamTypeNone) {
        orderedStreamTypes = [[orderedStreamTypes mtl_arrayByRemovingObject:@(streamType)] arrayByAddingObject:@(streamType)];
    }
    
    NSSortDescriptor *streamTypeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, streamType) ascending:NO comparator:^(NSNumber * _Nonnull streamType1, NSNumber * _Nonnull streamType2) {
        // Don't simply compare enum values as integers since their order might change.
        NSUInteger index1 = [orderedStreamTypes indexOfObject:streamType1];
        NSUInteger index2 = [orderedStreamTypes indexOfObject:streamType2];
        if (index1 == index2) {
            return NSOrderedSame;
        }
        else if (index1 < index2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    
    // Determine the quality to use (start with a default setup, overridden if a preferred value has been set).
    NSArray<NSNumber *> *orderedQualities = @[@(SRGQualitySD), @(SRGQualityHD), @(SRGQualityHQ)];
    SRGQuality quality = preferredSettings.quality;
    if (quality != SRGQualityNone) {
        orderedQualities = [[orderedQualities mtl_arrayByRemovingObject:@(quality)] arrayByAddingObject:@(quality)];
    }
    
    NSSortDescriptor *qualitySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, quality) ascending:NO comparator:^(NSNumber * _Nonnull quality1, NSNumber * _Nonnull quality2) {
        // Don't simply compare enum values as integers since their order might change.
        NSUInteger index1 = [orderedQualities indexOfObject:quality1];
        NSUInteger index2 = [orderedQualities indexOfObject:quality2];
        if (index1 == index2) {
            return NSOrderedSame;
        }
        else if (index1 < index2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    
    SRGResource *resource = [resources sortedArrayUsingDescriptors:@[URLSchemeSortDescriptor, streamTypeSortDescriptor, qualitySortDescriptor]].firstObject;
    if (! resource) {
        return NO;
    }
    
    SRGAnalyticsStreamLabels *labels = [self analyticsLabelsForResource:resource sourceUid:preferredSettings.sourceUid];
    NSInteger index = [chapter.segments indexOfObject:self.mainSegment];
    contextBlock(resource.URL, resource, chapter.segments, index, labels);
    return YES;
}

@end
