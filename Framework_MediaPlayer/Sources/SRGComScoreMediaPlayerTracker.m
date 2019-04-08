//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGComScoreMediaPlayerTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLabels+Private.h"
#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGAnalyticsStreamLabels.h"
#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <ComScore/ComScore.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

typedef NS_ENUM(NSInteger, ComScoreMediaPlayerTrackerEvent) {
    ComScoreMediaPlayerTrackerEventPlay = 1,
    ComScoreMediaPlayerTrackerEventPause,
    ComScoreMediaPlayerTrackerEventEnd,
    ComScoreMediaPlayerTrackerEventSeek,
    ComScoreMediaPlayerTrackerEventBuffer
};

static NSInteger s_playbackActivityCount = 0;
static NSMutableDictionary<NSValue *, SRGComScoreMediaPlayerTracker *> *s_trackers = nil;

@interface SRGComScoreMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic) SCORStreamingAnalytics *streamingAnalytics;

@property (nonatomic, getter=isPlaying) BOOL playing;

@end

@implementation SRGComScoreMediaPlayerTracker

#pragma mark Class methods

+ (void)increasePlaybackActivityCount
{
    ++s_playbackActivityCount;
    if (s_playbackActivityCount == 1) {
        [SCORAnalytics notifyUxActive];
    }
}

+ (void)decreasePlaybackActivityCount
{
    NSAssert(s_playbackActivityCount != 0, @"Incorrect activity count management");
    
    --s_playbackActivityCount;
    if (s_playbackActivityCount == 0) {
        [SCORAnalytics notifyUxInactive];
    }
}

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        
        self.streamingAnalytics = [[SCORStreamingAnalytics alloc] init];
        
        if (SRGAnalyticsTracker.sharedTracker.configuration.unitTesting) {
            [self.streamingAnalytics setLabelWithName:@"srg_test_id" value:SRGAnalyticsUnitTestingIdentifier()];
        }
        
        // Provide the analytics library version (most useful information) as player information.
        [self.streamingAnalytics setLabelWithName:@"ns_st_mp" value:@"SRGAnalytics"];
        [self.streamingAnalytics setLabelWithName:@"ns_st_mv" value:SRGAnalyticsMarketingVersion()];
        
        [self.streamingAnalytics createPlaybackSession];
        
        SRGAnalyticsStreamLabels *labels = mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey];
        if (labels.comScoreLabelsDictionary) {
            [self.streamingAnalytics.playbackSession setAssetWithLabels:labels.comScoreLabelsDictionary];
        }
        
        // No need to send explicit 'buffer stop' events. Sending a play or pause at the end of the buffering phase
        // (which our player does) suffices to implicitly finish the buffering phase. Buffer events are not required
        // to be sent when the player is seeking.
        [self.streamingAnalytics notifyBufferStart];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            
            SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
            if (mediaPlayerController.tracked) {
                [self recordEventForPlaybackState:mediaPlayerController.playbackState
                                   withStreamType:mediaPlayerController.streamType
                                             time:mediaPlayerController.currentTime
                                        timeRange:mediaPlayerController.timeRange];
            }
            else {
                [self recordEvent:ComScoreMediaPlayerTrackerEventEnd
                   withStreamType:mediaPlayerController.streamType
                             time:mediaPlayerController.currentTime
                        timeRange:mediaPlayerController.timeRange];
            }
        }];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

#pragma clang diagnostic pop

#pragma mark Tracking

- (void)recordEventForPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
                     withStreamType:(SRGMediaPlayerStreamType)streamType
                               time:(CMTime)time
                          timeRange:(CMTimeRange)timeRange
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_events;
    dispatch_once(&s_onceToken, ^{
        s_events = @{ @(SRGMediaPlayerPlaybackStateIdle) : @(ComScoreMediaPlayerTrackerEventEnd),
                      @(SRGMediaPlayerPlaybackStatePreparing) : @(ComScoreMediaPlayerTrackerEventBuffer),
                      @(SRGMediaPlayerPlaybackStatePlaying) : @(ComScoreMediaPlayerTrackerEventPlay),
                      @(SRGMediaPlayerPlaybackStateSeeking) : @(ComScoreMediaPlayerTrackerEventSeek),
                      @(SRGMediaPlayerPlaybackStatePaused) : @(ComScoreMediaPlayerTrackerEventPause),
                      @(SRGMediaPlayerPlaybackStateEnded) : @(ComScoreMediaPlayerTrackerEventEnd),
                      @(SRGMediaPlayerPlaybackStateStalled) : @(ComScoreMediaPlayerTrackerEventBuffer) };
    });
    
    NSNumber *event = s_events[@(playbackState)];
    if (! event) {
        return;
    }
    
    [self recordEvent:event.integerValue
       withStreamType:streamType
                 time:time
            timeRange:timeRange];
}

- (void)recordEvent:(ComScoreMediaPlayerTrackerEvent)event
     withStreamType:(SRGMediaPlayerStreamType)streamType
               time:(CMTime)time
          timeRange:(CMTimeRange)timeRange
{
    SCORStreamingAnalytics *streamingAnalytics = self.streamingAnalytics;
    
    if (! self.playing && event == ComScoreMediaPlayerTrackerEventPlay) {
        [SRGComScoreMediaPlayerTracker increasePlaybackActivityCount];
        self.playing = YES;
    }
    else if (self.playing && (event == ComScoreMediaPlayerTrackerEventPause || event == ComScoreMediaPlayerTrackerEventEnd)) {
        [SRGComScoreMediaPlayerTracker decreasePlaybackActivityCount];
        self.playing = NO;
    }
    
    if (streamType == SRGMediaPlayerStreamTypeDVR) {
        [streamingAnalytics setDVRWindowLength:SRGMediaAnalyticsCMTimeToMilliseconds(self.mediaPlayerController.timeRange.duration)];
        [streamingAnalytics setDVRWindowOffset:SRGMediaAnalyticsTimeshiftInMilliseconds(streamType, timeRange, time, self.mediaPlayerController.liveTolerance).integerValue];
        
        switch (event) {
            case ComScoreMediaPlayerTrackerEventPlay: {
                [streamingAnalytics notifyPlay];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventPause: {
                [streamingAnalytics notifyPause];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventEnd: {
                [streamingAnalytics notifyEnd];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventSeek: {
                [streamingAnalytics notifySeekStart];
                break;
            }
            
            case ComScoreMediaPlayerTrackerEventBuffer: {
                [streamingAnalytics notifyBufferStart];
                break;
            }
                
            default: {
                break;
            }
        }
    }
    else {
        long position = SRGMediaAnalyticsCMTimeToMilliseconds(time);
        switch (event) {
            case ComScoreMediaPlayerTrackerEventPlay: {
                [streamingAnalytics notifyPlayWithPosition:position];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventPause: {
                [streamingAnalytics notifyPauseWithPosition:position];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventEnd: {
                [streamingAnalytics notifyEndWithPosition:position];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventSeek: {
                [streamingAnalytics notifySeekStartWithPosition:position];
                break;
            }
                
            case ComScoreMediaPlayerTrackerEventBuffer: {
                [streamingAnalytics notifyBufferStartWithPosition:position];
                break;
            }
                
            default: {
                break;
            }
        }
    }
}

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    if (! SRGAnalyticsTracker.sharedTracker.configuration) {
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    NSValue *key = [NSValue valueWithNonretainedObject:mediaPlayerController];
    
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    
    // Always attach a tracker to a the player controller, whether or not it is actually tracked (otherwise we would
    // be unable to attach to initially untracked controller later).
    if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        SRGComScoreMediaPlayerTracker *tracker = [[SRGComScoreMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        s_trackers[key] = tracker;
        
        [tracker recordEvent:ComScoreMediaPlayerTrackerEventBuffer
              withStreamType:mediaPlayerController.streamType
                        time:mediaPlayerController.currentTime
                   timeRange:mediaPlayerController.timeRange];
        
        SRGAnalyticsMediaPlayerLogInfo(@"comScoreTracker", @"Started tracking for %@", key);
    }
    else if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGComScoreMediaPlayerTracker *tracker = s_trackers[key];
        if (tracker) {
            if (previousPlaybackState != SRGMediaPlayerPlaybackStatePreparing) {
                SRGMediaPlayerStreamType streamType = [notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey] integerValue];
                CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
                CMTimeRange timeRange = [notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue];
                [tracker recordEvent:ComScoreMediaPlayerTrackerEventEnd
                      withStreamType:streamType
                                time:time
                           timeRange:timeRange];
            }
            s_trackers[key] = nil;
            
            SRGAnalyticsMediaPlayerLogInfo(@"comScoreTracker", @"Stopped tracking for %@", key);
        }
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        return;
    }
    
    [self recordEventForPlaybackState:playbackState
                       withStreamType:mediaPlayerController.streamType
                                 time:mediaPlayerController.currentTime
                            timeRange:mediaPlayerController.timeRange];
}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [NSNotificationCenter.defaultCenter addObserver:SRGComScoreMediaPlayerTracker.class
                                           selector:@selector(playbackStateDidChange:)
                                               name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                             object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}
