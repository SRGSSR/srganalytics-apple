//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerTracker.h"

#import <objc/runtime.h>

static void *s_trackedKey = &s_trackedKey;
static void *s_analyticsPlayerNameKey = &s_analyticsPlayerNameKey;
static void *s_analyticsPlayerVersionKey = &s_analyticsPlayerVersionKey;

@implementation SRGMediaPlayerController (SRGAnalytics_MediaPlayer)

#pragma mark Class methods

+ (NSDictionary *)fullInfoWithAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                                     userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    fullUserInfo[SRGAnalyticsMediaPlayerLabelsKey] = [analyticsLabels copy];
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

#pragma mark Playback methods

- (void)prepareToPlayURL:(NSURL *)URL
              atPosition:(SRGPosition *)position
            withSegments:(NSArray<id<SRGSegment>> *)segments
         analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atPosition:position withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset
                   atPosition:(SRGPosition *)position
                 withSegments:(NSArray<id<SRGSegment>> *)segments
              analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                     userInfo:(NSDictionary *)userInfo
            completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURLAsset:URLAsset atPosition:position withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
     atPosition:(SRGPosition *)position
   withSegments:(NSArray<id<SRGSegment>> *)segments
analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atPosition:position withSegments:segments userInfo:fullUserInfo];
}

- (void)playURLAsset:(AVURLAsset *)URLAsset
          atPosition:(SRGPosition *)position
        withSegments:(NSArray<id<SRGSegment>> *)segments
     analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
            userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURLAsset:URLAsset atPosition:position withSegments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
                position:(SRGPosition *)position
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset
                      atIndex:(NSInteger)index
                     position:(SRGPosition *)position
                   inSegments:(NSArray<id<SRGSegment>> *)segments
          withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                     userInfo:(NSDictionary *)userInfo
            completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURLAsset:URLAsset atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
       position:(SRGPosition *)position
     inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo];
}

- (void)playURLAsset:(AVURLAsset *)URLAsset
             atIndex:(NSInteger)index
            position:(SRGPosition *)position
          inSegments:(NSArray<id<SRGSegment>> *)segments
 withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
            userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURLAsset:URLAsset atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo];
}

#pragma mark Getters and setters

- (BOOL)isTracked
{
    NSNumber *isTracked = objc_getAssociatedObject(self, s_trackedKey);
    return isTracked ? [isTracked boolValue] : YES;
}

- (void)setTracked:(BOOL)tracked
{
    objc_setAssociatedObject(self, s_trackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)analyticsPlayerName
{
    NSString *analyticsPlayerName = objc_getAssociatedObject(self, s_analyticsPlayerNameKey);
    return analyticsPlayerName ?: @"SRGMediaPlayer";
}

- (void)setAnalyticsPlayerName:(NSString *)analyticsPlayerName
{
    objc_setAssociatedObject(self, s_analyticsPlayerNameKey, analyticsPlayerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)analyticsPlayerVersion
{
    NSString *analyticsPlayerVersion = objc_getAssociatedObject(self, s_analyticsPlayerVersionKey);
    return analyticsPlayerVersion ?: SRGMediaPlayerMarketingVersion();
}

- (void)setAnalyticsPlayerVersion:(NSString *)analyticsPlayerVersion
{
    objc_setAssociatedObject(self, s_analyticsPlayerVersionKey, analyticsPlayerVersion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SRGAnalyticsStreamLabels *)analyticsLabels
{
    return self.userInfo[SRGAnalyticsMediaPlayerLabelsKey];
}

- (void)setAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
{
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    userInfo[SRGAnalyticsMediaPlayerLabelsKey] = analyticsLabels;
    self.userInfo = [userInfo copy];
}

@end
