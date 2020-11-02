//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "AVPlayerItem+SRGAnalyticsMediaPlayer.h"
#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLabels+Private.h"
#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGAnalyticsTracker+Private.h"
#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerController+SRGAnalyticsMediaPlayer.h"

@import libextobjc;
@import MAKVONotificationCenter;

#import <math.h>

typedef NSString * MediaPlayerTrackerEvent NS_TYPED_ENUM;

static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPlay = @"play";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPause = @"pause";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventSeek = @"seek";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventEnd = @"eof";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventStop = @"stop";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPosition = @"pos";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventUptime = @"uptime";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventSegment = @"segment";

static NSMutableDictionary<NSValue *, SRGMediaPlayerTracker *> *s_trackers = nil;

static NSString *SRGMediaPlayerTrackerLabelForSelectionReason(SRGMediaPlayerSelectionReason reason);

@interface SRGMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSTimeInterval playbackDuration;
@property (nonatomic) NSDate *previousPlaybackDurationUpdateDate;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@property (nonatomic, copy) MediaPlayerTrackerEvent lastEvent;

@property (nonatomic, copy) NSString *unitTestingIdentifier;

@end

@implementation SRGMediaPlayerTracker

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        SRGAnalyticsStreamLabels *mainLabels = mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey];
        if (mainLabels.labelsDictionary.count == 0) {
            return nil;
        }
        
        self.mediaPlayerController = mediaPlayerController;
        self.lastEvent = MediaPlayerTrackerEventStop;
        self.unitTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidStart:)
                                                   name:SRGMediaPlayerSegmentDidStartNotification
                                                 object:mediaPlayerController];
        
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            
            SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
            if (mediaPlayerController.tracked) {
                [self recordEventForPlaybackState:mediaPlayerController.playbackState
                                   withStreamType:mediaPlayerController.streamType
                                             time:mediaPlayerController.currentTime
                                        timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                                  analyticsLabels:nil
                                         userInfo:mediaPlayerController.userInfo];
            }
            else {
                [self recordEvent:MediaPlayerTrackerEventStop
                   withStreamType:mediaPlayerController.streamType
                             time:mediaPlayerController.currentTime
                        timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                  analyticsLabels:nil
                         userInfo:mediaPlayerController.userInfo];
            }
        }];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

- (void)dealloc
{
    self.heartbeatTimer = nil;      // Invalidate timer
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
}

#pragma mark Tracking

- (void)recordEventForPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
                     withStreamType:(SRGMediaPlayerStreamType)streamType
                               time:(CMTime)time
                          timeshift:(NSNumber *)timeshift
                    analyticsLabels:(NSDictionary<NSString *, NSString *> *)analyticsLabels
                           userInfo:(NSDictionary *)userInfo
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_events;
    dispatch_once(&s_onceToken, ^{
        s_events = @{ @(SRGMediaPlayerPlaybackStateIdle) : MediaPlayerTrackerEventStop,
                      @(SRGMediaPlayerPlaybackStatePlaying) : MediaPlayerTrackerEventPlay,
                      @(SRGMediaPlayerPlaybackStateSeeking) : MediaPlayerTrackerEventSeek,
                      @(SRGMediaPlayerPlaybackStatePaused) : MediaPlayerTrackerEventPause,
                      @(SRGMediaPlayerPlaybackStateEnded) : MediaPlayerTrackerEventEnd };
    });
    
    NSString *event = s_events[@(playbackState)];
    if (! event) {
        return;
    }
    
    [self recordEvent:event withStreamType:streamType time:time timeshift:timeshift analyticsLabels:analyticsLabels userInfo:userInfo];
}

- (void)recordEvent:(MediaPlayerTrackerEvent)event
     withStreamType:(SRGMediaPlayerStreamType)streamType
               time:(CMTime)time
          timeshift:(NSNumber *)timeshift
    analyticsLabels:(NSDictionary<NSString *, NSString *> *)analyticsLabels
           userInfo:(NSDictionary *)userInfo
{
    NSAssert(event.length != 0, @"An event is required");
    
    // Ensure a play is emitted before events requiring a session to be opened (the Tag Commander SDK does not open sessions
    // automatically)
    if ([self.lastEvent isEqualToString:MediaPlayerTrackerEventStop] && ([event isEqualToString:MediaPlayerTrackerEventPause] || [event isEqualToString:MediaPlayerTrackerEventSeek])) {
        [self recordEvent:MediaPlayerTrackerEventPlay withStreamType:streamType time:time timeshift:timeshift analyticsLabels:analyticsLabels userInfo:userInfo];
    }
    
    if (! [event isEqualToString:MediaPlayerTrackerEventPosition] && ! [event isEqualToString:MediaPlayerTrackerEventUptime] && ! [event isEqualToString:MediaPlayerTrackerEventSegment]) {
        static dispatch_once_t s_onceToken;
        static NSDictionary<NSString *, NSArray<NSString *> *> *s_transitions;
        dispatch_once(&s_onceToken, ^{
            s_transitions = @{ MediaPlayerTrackerEventPlay : @[ MediaPlayerTrackerEventPause, MediaPlayerTrackerEventSeek, MediaPlayerTrackerEventStop, MediaPlayerTrackerEventEnd ],
                               MediaPlayerTrackerEventPause : @[ MediaPlayerTrackerEventPlay, MediaPlayerTrackerEventSeek, MediaPlayerTrackerEventStop, MediaPlayerTrackerEventEnd ],
                               MediaPlayerTrackerEventSeek : @[ MediaPlayerTrackerEventPlay, MediaPlayerTrackerEventPause, MediaPlayerTrackerEventStop, MediaPlayerTrackerEventEnd ],
                               MediaPlayerTrackerEventStop : @[ MediaPlayerTrackerEventPlay ],
                               MediaPlayerTrackerEventEnd : @[ MediaPlayerTrackerEventPlay ] };
        });
        
        if (! [s_transitions[self.lastEvent] containsObject:event]) {
            return;
        }
        
        self.lastEvent = event;
        
        // Restore the heartbeat timer when transitioning to play again. We can use a simple `NSTimer` here since
        // it needs to run while playing content (even in background), but will otherwise be inactive.
        if ([event isEqualToString:MediaPlayerTrackerEventPlay]) {
            if (! self.heartbeatTimer) {
                SRGAnalyticsConfiguration *configuration = SRGAnalyticsTracker.sharedTracker.configuration;
                NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
                self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                                       target:self
                                                                     selector:@selector(heartbeat:)
                                                                     userInfo:nil
                                                                      repeats:YES];
                // Use the recommended 10% tolerance as default, see `tolerance` documentation
                self.heartbeatTimer.tolerance = heartbeatInterval / 10.;
                self.heartbeatCount = 0;
            }
        }
        // Remove the heartbeat when not playing
        else {
            self.heartbeatTimer = nil;
        }
    }
    
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    
    [labels srg_safelySetString:SRGAnalyticsTracker.sharedTracker.configuration.environment forKey:@"media_embedding_environment"];
    
    [labels srg_safelySetString:self.mediaPlayerController.analyticsPlayerName forKey:@"media_player_display"];
    [labels srg_safelySetString:self.mediaPlayerController.analyticsPlayerVersion forKey:@"media_player_version"];
    
    [labels srg_safelySetString:event forKey:@"event_id"];
    
    // Use current duration as media position for livestreams, raw position otherwise
    NSTimeInterval mediaPosition = SRGMediaAnalyticsIsLiveStreamType(streamType) ? [self updatedPlaybackDurationWithEvent:event] : SRGMediaAnalyticsCMTimeToMilliseconds(time);
    [labels srg_safelySetString:@(round(mediaPosition / 1000)).stringValue forKey:@"media_position"];
    
    [labels srg_safelySetString:self.playerVolumeInPercent.stringValue ?: @"0" forKey:@"media_volume"];
    
    AVMediaSelectionOption *subtitlesMediaOption = [self selectedMediaOptionForMediaCharacteristic:AVMediaCharacteristicLegible];
    [labels srg_safelySetString:subtitlesMediaOption != nil ? @"true" : @"false" forKey:@"media_subtitles_on"];
    if (subtitlesMediaOption) {
        NSString *subtitlesLanguageCode = [subtitlesMediaOption.locale objectForKey:NSLocaleLanguageCode] ?: @"und";
        [labels srg_safelySetString:subtitlesLanguageCode forKey:@"media_subtitle_selection"];
    }
    
    AVMediaSelectionOption *audioTrackMediaOption = [self selectedMediaOptionForMediaCharacteristic:AVMediaCharacteristicAudible];
    NSString *audioTrackLanguageCode = [audioTrackMediaOption.locale objectForKey:NSLocaleLanguageCode] ?: @"und";
    [labels srg_safelySetString:audioTrackLanguageCode forKey:@"media_audio_track"];
    
    [labels srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"media_bandwidth"];
    
    if (timeshift) {
        [labels srg_safelySetString:@(timeshift.integerValue / 1000).stringValue forKey:@"media_timeshift"];
    }
    
    if (analyticsLabels) {
        [labels addEntriesFromDictionary:analyticsLabels];
    }
    
    SRGAnalyticsStreamLabels *mainLabels = userInfo[SRGAnalyticsMediaPlayerLabelsKey];
    [labels addEntriesFromDictionary:mainLabels.labelsDictionary];
    
    if (SRGAnalyticsTracker.sharedTracker.configuration.unitTesting) {
        labels[@"srg_test_id"] = self.unitTestingIdentifier;
    }
    
    [SRGAnalyticsTracker.sharedTracker trackTagCommanderEventWithLabels:labels.copy];
}

#pragma mark Heartbeats

- (NSTimeInterval)updatedPlaybackDurationWithEvent:(MediaPlayerTrackerEvent)event
{
    if (self.previousPlaybackDurationUpdateDate) {
        self.playbackDuration -= [self.previousPlaybackDurationUpdateDate timeIntervalSinceNow] * 1000.;
    }
    
    if ([event isEqualToString:MediaPlayerTrackerEventPlay] || [event isEqualToString:MediaPlayerTrackerEventPosition] || [event isEqualToString:MediaPlayerTrackerEventUptime]) {
        self.previousPlaybackDurationUpdateDate = NSDate.date;
    }
    else {
        self.previousPlaybackDurationUpdateDate = nil;
    }
    
    NSTimeInterval playbackDuration = self.playbackDuration;
    
    if ([event isEqualToString:MediaPlayerTrackerEventStop] || [event isEqualToString:MediaPlayerTrackerEventEnd]) {
        self.playbackDuration = 0;
    }
    
    return playbackDuration;
}

#pragma mark Playback information

- (NSNumber *)bandwidthInBitsPerSecond
{
    AVPlayerItem *currentItem = self.mediaPlayerController.player.currentItem;
    if (! currentItem) {
        return nil;
    }
    
    NSArray<AVPlayerItemAccessLogEvent *> *events = currentItem.accessLog.events;
    if (! events.lastObject) {
        return nil;
    }
    
    double observedBitrate = events.lastObject.observedBitrate;
    if (isnan(observedBitrate) || observedBitrate < 0.) {
        return nil;
    }
    
    return @(observedBitrate);
}

- (NSNumber *)playerVolumeInPercent
{
    // AVPlayer has a volume property, but its purpose is NOT end-user volume control (see documentation). This volume is
    // therefore not relevant for our calculations.
    AVPlayer *player = self.mediaPlayerController.player;
    if (! player || player.muted) {
        return nil;
    }
    // When we have a non-muted player, its volume is simply the system volume (note that this volume does not take
    // into account the ringer status).
    else {
        NSInteger volume = [AVAudioSession sharedInstance].outputVolume * 100;
        return @(volume);
    }
}

- (AVMediaSelectionOption *)selectedMediaOptionForMediaCharacteristic:(AVMediaCharacteristic)mediaCharacteristic
{
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:mediaCharacteristic];
        return [playerItem srganalytics_selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    }
    else {
        return nil;
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
        SRGMediaPlayerTracker *tracker = [[SRGMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        if (tracker) {
            s_trackers[key] = tracker;
        
            SRGAnalyticsMediaPlayerLogInfo(@"tracker", @"Started tracking for %@", key);
        }
    }
    else if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        if (tracker) {
            if (previousPlaybackState != SRGMediaPlayerPlaybackStatePreparing) {
                SRGMediaPlayerStreamType streamType = [notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey] integerValue];
                CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
                NSNumber *timeshift = SRGMediaAnalyticsTimeshiftInMilliseconds(streamType,
                                                                               [notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue],
                                                                               [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue],
                                                                               mediaPlayerController.liveTolerance);
                [tracker recordEvent:MediaPlayerTrackerEventStop
                      withStreamType:streamType
                                time:time
                           timeshift:timeshift
                     analyticsLabels:nil
                            userInfo:notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]];
            }
            s_trackers[key] = nil;
            
            SRGAnalyticsMediaPlayerLogInfo(@"tracker", @"Stopped tracking for %@", key);
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
                            timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                      analyticsLabels:nil
                             userInfo:mediaPlayerController.userInfo];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        NSMutableDictionary<NSString *, NSString *> *analyticsLabels = [NSMutableDictionary dictionary];
        
        SRGMediaPlayerSelectionReason selectionReason = [notification.userInfo[SRGMediaPlayerSelectionReasonKey] integerValue];
        NSString *selectionReasonLabel = SRGMediaPlayerTrackerLabelForSelectionReason(selectionReason);
        analyticsLabels[@"segment_change_origin"] = selectionReasonLabel;
        
        [self recordEvent:MediaPlayerTrackerEventSegment
           withStreamType:mediaPlayerController.streamType
                     time:mediaPlayerController.currentTime
                timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
          analyticsLabels:analyticsLabels.copy
                 userInfo:mediaPlayerController.userInfo];
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
    NSNumber *timeshift = SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController);
    
    [self recordEvent:MediaPlayerTrackerEventPosition
       withStreamType:streamType
                 time:mediaPlayerController.currentTime
            timeshift:timeshift
      analyticsLabels:nil
             userInfo:mediaPlayerController.userInfo];
    
    // Send a live heartbeat each minute
    if (self.mediaPlayerController.live && self.heartbeatCount % 2 != 0) {
        [self recordEvent:MediaPlayerTrackerEventUptime
           withStreamType:streamType
                     time:mediaPlayerController.currentTime
                timeshift:timeshift
          analyticsLabels:nil
                 userInfo:mediaPlayerController.userInfo];
    }
    
    self.heartbeatCount += 1;
}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [NSNotificationCenter.defaultCenter addObserver:SRGMediaPlayerTracker.class
                                           selector:@selector(playbackStateDidChange:)
                                               name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                             object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}

static NSString *SRGMediaPlayerTrackerLabelForSelectionReason(SRGMediaPlayerSelectionReason reason)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary *s_labels;
    dispatch_once(&s_onceToken, ^{
        s_labels = @{ @(SRGMediaPlayerSelectionReasonInitial) : @"start",
                      @(SRGMediaPlayerSelectionReasonUpdate) : @"click" };
    });
    return s_labels[@(reason)];
}
