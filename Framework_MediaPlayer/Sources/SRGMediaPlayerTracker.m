//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "NSBundle+SRGAnalytics.h"
#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLabels+Private.h"
#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGAnalyticsSegment.h"
#import "SRGAnalyticsTracker+Private.h"
#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <math.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

typedef NSString * MediaPlayerTrackerEvent NS_TYPED_ENUM;

static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPlay = @"play";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPause = @"pause";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventSeek = @"seek";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventEnd = @"eof";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventStop = @"stop";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventPosition = @"pos";
static MediaPlayerTrackerEvent const MediaPlayerTrackerEventUptime = @"uptime";

static NSMutableDictionary<NSValue *, SRGMediaPlayerTracker *> *s_trackers = nil;

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
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidEnd:)
                                                   name:SRGMediaPlayerSegmentDidEndNotification
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
                                          segment:mediaPlayerController.selectedSegment
                                         userInfo:mediaPlayerController.userInfo];
            }
            else {
                [self recordEvent:MediaPlayerTrackerEventStop
                   withStreamType:mediaPlayerController.streamType
                             time:mediaPlayerController.currentTime
                        timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                          segment:mediaPlayerController.selectedSegment
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
                            segment:(id<SRGSegment>)segment
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
    
    [self recordEvent:event withStreamType:streamType time:time timeshift:timeshift segment:segment userInfo:userInfo];
}

- (void)recordEvent:(MediaPlayerTrackerEvent)event
     withStreamType:(SRGMediaPlayerStreamType)streamType
               time:(CMTime)time
          timeshift:(NSNumber *)timeshift
            segment:(id<SRGSegment>)segment
           userInfo:(NSDictionary *)userInfo
{
    NSAssert(event.length != 0, @"An event is required");
    
    // Ensure a play is emitted before events requiring a session to be opened (the Tag Commander SDK does not open sessions
    // automatically)
    if ([self.lastEvent isEqualToString:MediaPlayerTrackerEventStop] && ([event isEqualToString:MediaPlayerTrackerEventPause] || [event isEqualToString:MediaPlayerTrackerEventSeek])) {
        [self recordEvent:MediaPlayerTrackerEventPlay withStreamType:streamType time:time timeshift:timeshift segment:segment userInfo:userInfo];
    }
    
    if (! [event isEqualToString:MediaPlayerTrackerEventPosition] && ! [event isEqualToString:MediaPlayerTrackerEventUptime]) {
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
        
        // Restore the heartbeat timer when transitioning to play again.
        if ([event isEqualToString:MediaPlayerTrackerEventPlay]) {
            if (! self.heartbeatTimer) {
                SRGAnalyticsConfiguration *configuration = SRGAnalyticsTracker.sharedTracker.configuration;
                NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
                self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                                       target:self
                                                                     selector:@selector(heartbeat:)
                                                                     userInfo:nil
                                                                      repeats:YES];
                self.heartbeatCount = 0;
            }
        }
        // Remove the heartbeat when not playing
        else {
            self.heartbeatTimer = nil;
        }
    }
    
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    
    [labels srg_safelySetString:NSBundle.srg_isProductionVersion ? @"prod" : @"preprod" forKey:@"media_embedding_environment"];
    
    [labels srg_safelySetString:self.mediaPlayerController.analyticsPlayerName forKey:@"media_player_display"];
    [labels srg_safelySetString:self.mediaPlayerController.analyticsPlayerVersion forKey:@"media_player_version"];
    
    [labels srg_safelySetString:event forKey:@"event_id"];
    
    // Use current duration as media position for livestreams, raw position otherwise
    NSTimeInterval mediaPosition = SRGMediaAnalyticsIsLiveStreamType(streamType) ? [self updatedPlaybackDurationWithEvent:event] : SRGMediaAnalyticsCMTimeToMilliseconds(time);
    [labels srg_safelySetString:@(round(mediaPosition / 1000)).stringValue forKey:@"media_position"];
    
    [labels srg_safelySetString:self.playerVolumeInPercent.stringValue ?: @"0" forKey:@"media_volume"];
    [labels srg_safelySetString:self.subtitlesEnabled ? @"true" : @"false" forKey:@"media_subtitles_on"];
    
    [labels srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"media_bandwidth"];
    
    if (timeshift) {
        [labels srg_safelySetString:@(timeshift.integerValue / 1000).stringValue forKey:@"media_timeshift"];
    }
    
    SRGAnalyticsStreamLabels *mainLabels = userInfo[SRGAnalyticsMediaPlayerLabelsKey];
    [labels addEntriesFromDictionary:mainLabels.labelsDictionary];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        SRGAnalyticsStreamLabels *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        [labels addEntriesFromDictionary:segmentLabels.labelsDictionary];
    }
    
    if (SRGAnalyticsTracker.sharedTracker.configuration.unitTesting) {
        labels[@"srg_test_id"] = self.unitTestingIdentifier;
    }
    
    [SRGAnalyticsTracker.sharedTracker trackTagCommanderEventWithLabels:[labels copy]];
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

- (NSString *)windowState
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    CGRect screenRect = UIScreen.mainScreen.bounds;
    return roundf(size.width) == roundf(screenRect.size.width) && roundf(size.height) == roundf(screenRect.size.height) ? @"full" : @"norm";
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

- (NSString *)scalingMode
{
    static NSDictionary<NSString *, NSString *> *s_gravities;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_gravities = @{ AVLayerVideoGravityResize: @"fill",
                         AVLayerVideoGravityResizeAspect : @"fit-a",
                         AVLayerVideoGravityResizeAspectFill : @"fill-a" };
    });
    return s_gravities[self.mediaPlayerController.playerLayer.videoGravity] ?: @"no";
}

- (NSString *)orientation
{
    static NSDictionary<NSNumber *, NSString *> *s_orientations;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_orientations = @{ @(UIDeviceOrientationFaceDown) : @"facedown",
                            @(UIDeviceOrientationFaceUp) : @"faceup",
                            @(UIDeviceOrientationPortrait) : @"pt",
                            @(UIDeviceOrientationPortraitUpsideDown) : @"updown",
                            @(UIDeviceOrientationLandscapeLeft) : @"left",
                            @(UIDeviceOrientationLandscapeRight) : @"right" };
    });
    return s_orientations[@(UIDevice.currentDevice.orientation)];
}

- (NSString *)dimensions
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    return [NSString stringWithFormat:@"%0.fx%0.f", size.width, size.height];
}

- (NSString *)screenType
{
    if (self.mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
        return @"pip";
    }
    else if (self.mediaPlayerController.player.isExternalPlaybackActive) {
        return @"airplay";
    }
    else {
        return @"default";
    }
}

- (BOOL)subtitlesEnabled
{
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    return currentLegibleOption != nil;
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
                             segment:notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]
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
    
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    [self recordEventForPlaybackState:playbackState
                       withStreamType:mediaPlayerController.streamType
                                 time:mediaPlayerController.currentTime
                            timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                              segment:mediaPlayerController.selectedSegment
                             userInfo:mediaPlayerController.userInfo];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
        
        // Notify full-length end (only if not starting at the given segment, i.e. if the player is not preparing playback)
        if (! notification.userInfo[SRGMediaPlayerPreviousSegmentKey]
                && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
            NSNumber *timeshift = SRGMediaAnalyticsTimeshiftInMilliseconds(streamType, mediaPlayerController.timeRange, time, mediaPlayerController.liveTolerance);
            
            [self recordEvent:MediaPlayerTrackerEventStop
               withStreamType:streamType
                         time:time
                    timeshift:timeshift
                      segment:nil
                     userInfo:mediaPlayerController.userInfo];
        }
        
        [self recordEvent:MediaPlayerTrackerEventPlay
           withStreamType:streamType
                     time:mediaPlayerController.currentTime
                timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                  segment:notification.userInfo[SRGMediaPlayerSegmentKey]
                 userInfo:mediaPlayerController.userInfo];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
        
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
        NSNumber *timeshift = SRGMediaAnalyticsTimeshiftInMilliseconds(streamType, mediaPlayerController.timeRange, time, mediaPlayerController.liveTolerance);
        
        // Notify full-length start if the transition was not due to another segment being selected
        if (! [notification.userInfo[SRGMediaPlayerSelectionKey] boolValue] && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            BOOL interrupted = [notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue];
            [self recordEvent:interrupted ? MediaPlayerTrackerEventStop : MediaPlayerTrackerEventEnd
               withStreamType:streamType
                         time:time
                    timeshift:timeshift
                      segment:segment
                     userInfo:mediaPlayerController.userInfo];
            [self recordEvent:MediaPlayerTrackerEventPlay
               withStreamType:streamType
                         time:mediaPlayerController.currentTime
                    timeshift:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(mediaPlayerController)
                      segment:nil
                     userInfo:mediaPlayerController.userInfo];
        }
        else {
            [self recordEvent:MediaPlayerTrackerEventStop
               withStreamType:streamType
                         time:time
                    timeshift:timeshift
                      segment:segment
                     userInfo:mediaPlayerController.userInfo];
        }
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
              segment:mediaPlayerController.selectedSegment
             userInfo:mediaPlayerController.userInfo];
    
    // Send a live heartbeat each minute
    if (self.mediaPlayerController.live && self.heartbeatCount % 2 != 0) {
        [self recordEvent:MediaPlayerTrackerEventUptime
           withStreamType:streamType
                     time:mediaPlayerController.currentTime
                timeshift:timeshift
                  segment:mediaPlayerController.selectedSegment
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
