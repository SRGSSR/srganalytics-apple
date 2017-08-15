//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsSegment.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <ComScore/ComScore.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>

static void *s_kvoContext = &s_kvoContext;

NSString * const SRGAnalyticsMediaPlayerLabelsKey = @"SRGAnalyticsMediaPlayerLabelsKey";

static long SRGAnalyticsCMTimeToMilliseconds(CMTime time)
{
    return (long)fmax(floor(CMTimeGetSeconds(time) * 1000.), 0.);
}

static NSMutableDictionary *s_trackers = nil;

@interface SRGMediaPlayerTracker () {
@private
    BOOL _enabled;
}

@property (nonatomic) SRGAnalyticsPlayerTracker *playerTracker;

// We must not retain the controller, so that its deallocation is not prevented (deallocation will ensure the idle state
// is always reached before the player gets destroyed, and our tracker is removed when this state is reached). Since
// returning to the idle state might occur during deallocation, we need a non-weak ref (which would otherwise be nilled
// and thus not available when the tracker is stopped)
@property (nonatomic, unsafe_unretained) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic, readonly) long currentPositionInMilliseconds;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@property (nonatomic) SRGAnalyticsPlayerLabels *recentLabels;

@end

@implementation SRGMediaPlayerTracker

@synthesize currentPositionInMilliseconds = _currentPositionInMilliseconds;

#pragma mark Object lifecycle

- (id)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        self.playerTracker = [[SRGAnalyticsPlayerTracker alloc] init];
    }
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

- (void)dealloc
{
    self.heartbeatTimer = nil;      // Invalidate timer
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
    self.heartbeatCount = 0;
}

- (long)currentPositionInMilliseconds
{
    // Live stream: Playhead position must be always 0
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive || self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        return 0;
    }
    else {
        CMTime currentTime = [self.mediaPlayerController.player.currentItem currentTime];
        if (CMTIME_IS_INDEFINITE(currentTime) || CMTIME_IS_INVALID(currentTime)) {
            return 0;
        }
        else {
            return SRGAnalyticsCMTimeToMilliseconds(currentTime);
        }
    }
}

#pragma mark Tracker management

- (void)start
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidStart:)
                                                 name:SRGMediaPlayerSegmentDidStartNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidEnd:)
                                                 name:SRGMediaPlayerSegmentDidEndNotification
                                               object:self.mediaPlayerController];
    
    [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventBuffer atPosition:self.currentPositionInMilliseconds withSegment:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        
        // Balance events if the player is already playing, so that all events can be properly emitted afterwards
        if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            SRGAnalyticsPlayerEvent event = self.mediaPlayerController.tracked ? SRGAnalyticsPlayerEventPlay : SRGAnalyticsPlayerEventStop;
            [self trackEvent:event withSegment:self.mediaPlayerController.selectedSegment];
        }
        else if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking) {
            SRGAnalyticsPlayerEvent event = self.mediaPlayerController.tracked ? SRGAnalyticsPlayerEventPlay : SRGAnalyticsPlayerEventStop;
            [self trackEvent:event withSegment:self.mediaPlayerController.selectedSegment];
            
            // Also send the seek event when starting tracking, so that the current player state is accurately reflected
            if (self.mediaPlayerController.tracked) {
                [self trackEvent:SRGAnalyticsPlayerEventSeek withSegment:self.mediaPlayerController.selectedSegment];
            }
        }
        else if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused) {
            SRGAnalyticsPlayerEvent event = self.mediaPlayerController.tracked ? SRGAnalyticsPlayerEventPlay : SRGAnalyticsPlayerEventStop;
            [self trackEvent:event withSegment:self.mediaPlayerController.selectedSegment];
            
            // Also send the pause event when starting tracking, so that the current player state is accurately reflected
            if (self.mediaPlayerController.tracked) {
                [self trackEvent:SRGAnalyticsPlayerEventPause withSegment:self.mediaPlayerController.selectedSegment];
            }
        }
        
        [self updateHearbeatTimer];
    }];
}

- (void)stopAtPosition:(NSTimeInterval)position withLabels:(SRGAnalyticsPlayerLabels *)labels
{
    NSAssert(self.mediaPlayerController, @"Media player controller must be available when stopping");
    
    self.heartbeatTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidStartNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidEndNotification
                                                  object:self.mediaPlayerController];
    
    [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventStop atPosition:position withLabels:labels segment:self.mediaPlayerController.selectedSegment];
    
    [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked)];
    
    self.recentLabels = nil;
    self.mediaPlayerController = nil;
}

- (void)updateHearbeatTimer
{
    if (self.mediaPlayerController.tracked && self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying && ! self.heartbeatTimer) {
        SRGAnalyticsConfiguration *configuration = [SRGAnalyticsTracker sharedTracker].configuration;
        NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
        self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                               target:self
                                                             selector:@selector(heartbeat:)
                                                             userInfo:nil
                                                              repeats:YES];
    }
    else {
        self.heartbeatTimer = nil;
    }
}

#pragma mark Measurement methods (only sending events when the controller is tracked)

- (void)measureTrackedPlayerEvent:(SRGAnalyticsPlayerEvent)event
                       atPosition:(NSTimeInterval)position
                       withLabels:(SRGAnalyticsPlayerLabels *)labels
                          segment:(id<SRGSegment>)segment
{
    if (! self.mediaPlayerController.tracked) {
        return;
    }
    
    [self trackEvent:event atPosition:position withLabels:labels segment:segment];
}

- (void)measureTrackedPlayerEvent:(SRGAnalyticsPlayerEvent)event
                       atPosition:(NSTimeInterval)position
                      withSegment:(id<SRGSegment>)segment
{
    [self measureTrackedPlayerEvent:event
                         atPosition:position
                         withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                            segment:segment];
}

#pragma mark Force tracking (always send events, whether the controller is tracked or not)

- (void)trackEvent:(SRGAnalyticsPlayerEvent)event atPosition:(NSTimeInterval)position withLabels:(SRGAnalyticsPlayerLabels *)labels segment:(id<SRGSegment>)segment
{
    SRGAnalyticsPlayerLabels *playerLabels = [[SRGAnalyticsPlayerLabels alloc] init];
    playerLabels.playerName = @"SRGMediaPlayer";
    playerLabels.playerVersion = SRGMediaPlayerMarketingVersion();
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    playerLabels.subtitlesEnabled = @(currentLegibleOption != nil);
    
    playerLabels.timeshiftInMilliseconds = [self timeshiftInMilliseconds];
    playerLabels.bandwidthInBitsPerSecond = [self bandwidthInBitsPerSecond];
    playerLabels.volumeInPercent = [self volumeInPercent];
    
    // comScore-only labels
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomInfo = [NSMutableDictionary dictionary];
    [comScoreCustomInfo srg_safelySetString:[self windowState] forKey:@"ns_st_ws"];
    [comScoreCustomInfo srg_safelySetString:[self scalingMode] forKey:@"ns_st_sg"];
    [comScoreCustomInfo srg_safelySetString:[self orientation] forKey:@"ns_ap_ot"];
    playerLabels.comScoreCustomInfo = [comScoreCustomInfo copy];
    
    // comScore-only clip labels
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomSegmentInfo = [NSMutableDictionary dictionary];
    [comScoreCustomSegmentInfo srg_safelySetString:[self dimensions] forKey:@"ns_st_cs"];
    [comScoreCustomSegmentInfo srg_safelySetString:[self screenType] forKey:@"srg_screen_type"];
    playerLabels.comScoreCustomSegmentInfo = [comScoreCustomSegmentInfo copy];
    
    SRGAnalyticsPlayerLabels *fullLabels = labels ? [labels copy] : [[SRGAnalyticsPlayerLabels alloc] init];
    [fullLabels mergeWithLabels:playerLabels];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        SRGAnalyticsPlayerLabels *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        [fullLabels mergeWithLabels:segmentLabels];
    }
    
    self.recentLabels = fullLabels;
    [self.playerTracker trackPlayerEvent:event atPosition:position withLabels:fullLabels];
}

- (void)trackEvent:(SRGAnalyticsPlayerEvent)event withSegment:(id<SRGSegment>)segment
{
    NSDictionary *userInfo = self.mediaPlayerController.userInfo;
    [self trackEvent:event atPosition:self.currentPositionInMilliseconds withLabels:userInfo[SRGAnalyticsMediaPlayerLabelsKey] segment:segment];
}

#pragma mark Playback data

- (NSNumber *)bandwidthInBitsPerSecond
{
    AVPlayerItem *currentItem = self.mediaPlayerController.player.currentItem;
    if (! currentItem) {
        return nil;
    }
    
    NSArray *events = currentItem.accessLog.events;
    if (! events.lastObject) {
        return nil;
    }
    
    double observedBitrate = [events.lastObject observedBitrate];
    return @(observedBitrate);
}

- (NSString *)windowState
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    CGRect screenRect = [UIScreen mainScreen].bounds;
    return roundf(size.width) == roundf(screenRect.size.width) && roundf(size.height) == roundf(screenRect.size.height) ? @"full" : @"norm";
}

- (NSNumber *)volumeInPercent
{
    if (! self.mediaPlayerController.player) {
        return nil;
    }
    else if (self.mediaPlayerController.player.isMuted) {
        return @0;
    }
    else {
        return @(self.mediaPlayerController.player.volume * 100);
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
    return s_orientations[@([UIDevice currentDevice].orientation)];
}

- (NSString *)dimensions
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    return [NSString stringWithFormat:@"%0.fx%0.f", size.width, size.height];
}

- (NSNumber *)timeshiftInMilliseconds
{
    // Do not return any value for non-live streams
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), self.mediaPlayerController.player.currentItem.currentTime);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= self.mediaPlayerController.liveTolerance) {
            return @0;
        }
        else {
            return @(timeShiftInSeconds * 1000);
        }
    }
    else if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive) {
        return @0;
    }
    else {
        return nil;
    }
}

- (NSString *)airplay
{
    return self.mediaPlayerController.player.isExternalPlaybackActive ? @"1" : @"0";
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

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    if (! [SRGAnalyticsTracker sharedTracker].configuration) {
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    NSValue *key = [NSValue valueWithNonretainedObject:mediaPlayerController];
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        NSAssert(s_trackers[key] == nil, @"No tracker must exist");
        SRGMediaPlayerTracker *tracker = [[SRGMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        
        s_trackers[key] = tracker;
        if (s_trackers.count == 1) {
            [CSComScore onUxActive];
        }
        
        [tracker start];
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Started tracking for %@", key);
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        NSAssert(tracker != nil, @"A tracker must exist");
        
        NSDictionary *previousUserInfo = notification.userInfo[SRGMediaPlayerPreviousUserInfoKey];
        NSValue *lastPlaybackTimeValue = notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey];
        NSTimeInterval lastPositionInMilliseconds = SRGAnalyticsCMTimeToMilliseconds([lastPlaybackTimeValue CMTimeValue]);
        
        [tracker stopAtPosition:lastPositionInMilliseconds withLabels:previousUserInfo[SRGAnalyticsMediaPlayerLabelsKey]];
        
        [s_trackers removeObjectForKey:key];
        if (s_trackers.count == 0) {
            [CSComScore onUxInactive];
        }
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Stopped tracking for %@", key);
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateHearbeatTimer];
    
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    SRGAnalyticsPlayerEvent event;
    switch (self.mediaPlayerController.playbackState) {
        case SRGMediaPlayerPlaybackStatePlaying: {
            event = SRGAnalyticsPlayerEventPlay;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking:
            event = SRGAnalyticsPlayerEventSeek;
            break;
            
        case SRGMediaPlayerPlaybackStatePaused: {
            event = SRGAnalyticsPlayerEventPause;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateStalled: {
            event = SRGAnalyticsPlayerEventBuffer;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateEnded: {
            event = SRGAnalyticsPlayerEventEnd;
            break;
        }
            
        default: {
            return;
            break;
        }
    }
    
    [self measureTrackedPlayerEvent:event atPosition:self.currentPositionInMilliseconds withSegment:self.mediaPlayerController.selectedSegment];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    // Only send analytics for segment selections
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        // Notify full-length end (only if not starting at the given segment, i.e. if the player is not preparing playback)
        id<SRGSegment> previousSegment = notification.userInfo[SRGMediaPlayerPreviousSegmentKey];
        if (! previousSegment && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            NSValue *lastPlaybackTimeValue = notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey];
            NSTimeInterval lastPositionInMilliseconds = SRGAnalyticsCMTimeToMilliseconds([lastPlaybackTimeValue CMTimeValue]);
            
            [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventStop atPosition:lastPositionInMilliseconds withSegment:nil];
        }
        
        [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventPlay atPosition:self.currentPositionInMilliseconds withSegment:segment];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    // Only send analytics for segments which were selected
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        NSValue *lastPlaybackTimeValue = notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey];
        NSTimeInterval lastPositionInMilliseconds = SRGAnalyticsCMTimeToMilliseconds([lastPlaybackTimeValue CMTimeValue]);
        
        // Notify full-length start if the transition was not due to another segment being selected
        if (! [notification.userInfo[SRGMediaPlayerSelectionKey] boolValue] && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            SRGAnalyticsPlayerEvent endEvent = [notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue] ? SRGAnalyticsPlayerEventStop : SRGAnalyticsPlayerEventEnd;
            NSTimeInterval endTimeInterval = (endEvent == SRGAnalyticsPlayerEventStop) ? lastPositionInMilliseconds : self.currentPositionInMilliseconds;

            [self measureTrackedPlayerEvent:endEvent atPosition:endTimeInterval withSegment:segment];
            [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventPlay atPosition:self.currentPositionInMilliseconds withSegment:nil];
        }
        else {
            [self measureTrackedPlayerEvent:SRGAnalyticsPlayerEventStop atPosition:lastPositionInMilliseconds withSegment:segment];
        }
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        [self.playerTracker trackPlayerEvent:SRGAnalyticsPlayerEventHeartbeat atPosition:self.currentPositionInMilliseconds withLabels:self.recentLabels];
        
        // Send a live hearbeat each minute
        if (self.mediaPlayerController.live && self.heartbeatCount % 2 == 0) {
            [self.playerTracker trackPlayerEvent:SRGAnalyticsPlayerEventLiveHeartbeat atPosition:self.currentPositionInMilliseconds withLabels:self.recentLabels];
        }
    }
    
    self.heartbeatCount += 1;
}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [[NSNotificationCenter defaultCenter] addObserver:[SRGMediaPlayerTracker class]
                                             selector:@selector(playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}
