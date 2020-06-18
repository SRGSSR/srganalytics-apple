//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGMediaComposition+SRGAnalytics_DataProvider.h"
#import "SRGMediaComposition+SRGAnalytics_DataProvider_Private.h"
#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>
#import <SRGContentProtection/SRGContentProtection.h>

NSString * const SRGAnalyticsDataProviderUserInfoResourceLoaderOptionsKey = @"SRGAnalyticsDataProviderUserInfoResourceLoaderOptions";

static NSString * const SRGAnalyticsDataProviderMediaCompositionKey = @"SRGAnalyticsDataProviderMediaComposition";
static NSString * const SRGAnalyticsDataProviderResourceKey = @"SRGAnalyticsDataProviderResource";
static NSString * const SRGAnalyticsDataProviderSourceUidKey = @"SRGAnalyticsDataProviderSourceUid";

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Playback methods

- (BOOL)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                           atPosition:(SRGPosition *)position
                withPreferredSettings:(SRGPlaybackSettings *)preferredSettings
                             userInfo:(NSDictionary *)userInfo
                    completionHandler:(void (^)(void))completionHandler
{
    return [mediaComposition playbackContextWithPreferredSettings:preferredSettings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
        if (resource.presentation == SRGPresentation360) {
            if (self.view.viewMode == SRGMediaPlayerViewModeFlat) {
                self.view.viewMode = SRGMediaPlayerViewModeMonoscopic;
            }
        }
        else {
            self.view.viewMode = SRGMediaPlayerViewModeFlat;
        }
        
        NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
        fullUserInfo[SRGAnalyticsDataProviderMediaCompositionKey] = mediaComposition;
        fullUserInfo[SRGAnalyticsDataProviderResourceKey] = resource;
        fullUserInfo[SRGAnalyticsDataProviderSourceUidKey] = preferredSettings.sourceUid;
        if (userInfo) {
            [fullUserInfo addEntriesFromDictionary:userInfo];
        }
        
        NSTimeInterval streamOffsetInSeconds = resource.streamOffset / 1000.;
        if (streamOffsetInSeconds != 0.) {
            fullUserInfo[SRGMediaPlayerUserInfoStreamOffsetKey] = [NSValue valueWithCMTime:CMTimeMakeWithSeconds(streamOffsetInSeconds, NSEC_PER_SEC)];
        }
        
        NSDictionary<SRGResourceLoaderOption, id> *options = userInfo[SRGAnalyticsDataProviderUserInfoResourceLoaderOptionsKey];
        NSAssert(! options || [options isKindOfClass:NSDictionary.class], @"Resource loader options must be provided as a dictionary");
        
        AVURLAsset *URLAsset = nil;
        
        SRGDRM *fairPlayDRM = [resource DRMWithType:SRGDRMTypeFairPlay];
        if (fairPlayDRM) {
            URLAsset = [AVURLAsset srg_fairPlayProtectedAssetWithURL:streamURL certificateURL:fairPlayDRM.certificateURL options:options];
        }
        else if (resource.tokenType == SRGTokenTypeAkamai) {
            URLAsset = [AVURLAsset srg_akamaiTokenProtectedAssetWithURL:streamURL options:options];
        }
        else {
            URLAsset = [AVURLAsset assetWithURL:streamURL];
        }
        
        [self prepareToPlayURLAsset:URLAsset atIndex:index position:position inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:fullUserInfo.copy completionHandler:^{
            completionHandler ? completionHandler() : nil;
        }];
    }];
}

- (BOOL)playMediaComposition:(SRGMediaComposition *)mediaComposition
                  atPosition:(SRGPosition *)position
       withPreferredSettings:(SRGPlaybackSettings *)preferredSettings
                    userInfo:(NSDictionary *)userInfo
{
    return [self prepareToPlayMediaComposition:mediaComposition atPosition:position withPreferredSettings:preferredSettings userInfo:userInfo completionHandler:^{
        [self play];
    }];
}

#pragma mark Getters and setters

- (void)setMediaComposition:(SRGMediaComposition *)mediaComposition
{
    SRGMediaComposition *currentMediaComposition = self.userInfo[SRGAnalyticsDataProviderMediaCompositionKey];
    if (! currentMediaComposition || ! mediaComposition) {
        return;
    }
    
    if (! [currentMediaComposition.mainChapter isEqual:mediaComposition.mainChapter]) {
        return;
    }
    
    NSMutableDictionary *userInfo = self.userInfo.mutableCopy;
    userInfo[SRGAnalyticsDataProviderMediaCompositionKey] = mediaComposition;
    self.userInfo = userInfo.copy;
    
    // Synchronize analytics labels
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(self.resource.quality)];
    SRGResource *resource = [[mediaComposition.mainChapter resourcesForStreamingMethod:self.resource.streamingMethod] filteredArrayUsingPredicate:predicate].firstObject;
    self.analyticsLabels = [mediaComposition analyticsLabelsForResource:resource sourceUid:self.userInfo[SRGAnalyticsDataProviderSourceUidKey]];
    
    self.segments = mediaComposition.mainChapter.segments;
}

- (SRGMediaComposition *)mediaComposition
{
    return self.userInfo[SRGAnalyticsDataProviderMediaCompositionKey];
}

- (SRGResource *)resource
{
    return self.userInfo[SRGAnalyticsDataProviderResourceKey];
}

@end
