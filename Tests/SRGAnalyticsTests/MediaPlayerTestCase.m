//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "Segment.h"
#import "TrackerSingletonSetup.h"
#import "XCTestCase+Tests.h"

@import MediaAccessibility;
@import SRGAnalyticsMediaPlayer;

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *OnDemandMultiAudioTracksTestURL(void)
{
    return [NSURL URLWithString:@"https://rts-vod-amd.akamaized.net/ww/8806923/f896dc42-b777-387e-9767-9e8821b502e9/master.m3u8"];
}

static NSURL *OnDemandVideoWithoutAudioTestURL(void)
{
    return [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/gear1/prog_index.m3u8"];
}

static NSURL *OnDemandAudioTestURL(void)
{
    return [NSURL URLWithString:@"https://rts-aod-dd.akamaized.net/ww/8849864/73bab428-ce6e-3ded-92cf-c84649ed766f.mp3"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"https://rtsc3video.akamaized.net/hls/live/2042837/c3video/3/playlist.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"https://rtsc3video.akamaized.net/hls/live/2042837/c3video/3/playlist.m3u8"];
}

@interface MediaPlayerTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation MediaPlayerTestCase

#pragma mark Setup and teardown

+ (void)setUp
{
    SetupTestSingletonTracker();
}

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Helpers

- (void)prepareToPlayURL:(NSURL *)URL
              atPosition:(SRGPosition *)position
            withSegments:(NSArray<id<SRGSegment>> *)segments
       completionHandler:(void (^)(void))completionHandler
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"test_label" : @"test_value" };
    [self.mediaPlayerController prepareToPlayURL:URL atPosition:position withSegments:segments analyticsLabels:labels userInfo:nil completionHandler:completionHandler];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
                position:(SRGPosition *)position
              inSegments:(NSArray<id<SRGSegment>> *)segments
       completionHandler:(void (^)(void))completionHandler
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"test_label" : @"test_value" };
    [self.mediaPlayerController prepareToPlayURL:URL atIndex:index position:position inSegments:segments withAnalyticsLabels:labels userInfo:nil completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
     atPosition:(SRGPosition *)position
   withSegments:(NSArray<id<SRGSegment>> *)segments
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"test_label" : @"test_value" };
    [self.mediaPlayerController playURL:URL atPosition:position withSegments:segments analyticsLabels:labels userInfo:nil];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
       position:(SRGPosition *)position
     inSegments:(NSArray<id<SRGSegment>> *)segments
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"test_label" : @"test_value" };
    [self.mediaPlayerController playURL:URL atIndex:index position:position inSegments:segments withAnalyticsLabels:labels userInfo:nil];
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil completionHandler:^{
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEntirePlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"1795");
            playReceived = YES;
        }
        return seekReceived && playReceived;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"eof");
        XCTAssertEqualObjects(labels[@"media_position"], @"1800");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testReplay
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [event isEqualToString:@"eof"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"media_position"], @"1800");
        return YES;
    }];
    
    SRGPosition *position = [SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController seekToPosition:position withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaySeekPlay
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertTrue(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return seekReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    XCTAssertEqual(count2, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testSeekWhilePaused
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(pauseReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"pause"]) {
            XCTAssertTrue(seekReceived);
            XCTAssertFalse(pauseReceived);
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            pauseReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return seekReceived && pauseReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPlayPausePlay
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testConsecutiveMedias
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full1");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels1 = [[SRGAnalyticsStreamLabels alloc] init];
    labels1.customInfo = @{ @"stream_name" : @"full1" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels1 userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full1");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels2 = [[SRGAnalyticsStreamLabels alloc] init];
    labels2.customInfo = @{ @"stream_name" : @"full2" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:labels2 userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full2");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full2");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaError
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return YES;
    }];
    
    [self playURL:[NSURL URLWithString:@"http://httpbin.org/status/403"] atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testWithoutLabels
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testCommonLabels
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"navigation_app_site_name"], @"rts-app-test-v");
        XCTAssertEqualObjects(labels[@"navigation_environment"], @"preprod");
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], SRGMediaPlayerMarketingVersion());
        XCTAssertEqualObjects(labels[@"test_label"], @"test_value");
        XCTAssertEqualObjects(labels[@"consent_services"], @"service1,service2,service3");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testCommonLabelsOverride
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"CustomPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], @"1.0");
        return YES;
    }];
    
    self.mediaPlayerController.analyticsPlayerName = @"CustomPlayer";
    self.mediaPlayerController.analyticsPlayerVersion = @"1.0";
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"CustomPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], @"1.0");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"CustomPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], @"1.0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], SRGMediaPlayerMarketingVersion());
        return YES;
    }];
    
    self.mediaPlayerController.analyticsPlayerName = nil;
    self.mediaPlayerController.analyticsPlayerVersion = nil;
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandPlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        XCTAssertNil(labels[@"media_timeshift"]);
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        XCTAssertNil(labels[@"media_timeshift"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLivePlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when paused");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRPlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:DVRTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
            XCTAssertEqualObjects(labels[@"media_position"], @"1");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"45");
            XCTAssertEqualObjects(labels[@"media_position"], @"1");
            playReceived = YES;
        }
        return seekReceived && playReceived;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(45., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"44");       // Not 45 because of chunks
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveStopLive
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when paused");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVolumeLabel
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_volume"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        player.muted = YES;
    };
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertNotNil(labels[@"media_volume"]);
        return YES;
    }];
    
    self.mediaPlayerController.player.muted = NO;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBandwidthLabel
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertNotEqualObjects(labels[@"media_bandwidth"], @"0");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertNil(labels[@"media_bandwidth"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnvironment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"en");
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSubtitlesDuringEntirePlayback
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"en");
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
            XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
            XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
            playReceived = YES;
        }
        return seekReceived && playReceived;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"eof");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_subtitle_selection"], @"EN");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertNil(labels[@"media_subtitle_selection"]);
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertNil(labels[@"media_subtitle_selection"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSubtitlesForAudioContent
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertNil(labels[@"media_subtitle_selection"]);
        return YES;
    }];
    
    [self playURL:OnDemandAudioTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertNil(labels[@"media_subtitle_selection"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDefaultAudioTrack
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"EN");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"EN");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoAudioTrackInformation
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"UND");
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"UND");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoAudioTrack
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertNil(labels[@"media_audio_track"]);
        return YES;
    }];
    
    [self playURL:OnDemandVideoWithoutAudioTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertNil(labels[@"media_audio_track"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAudioTrackForAudioContent
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertNil(labels[@"media_audio_track"]);
        return YES;
    }];
    
    [self playURL:OnDemandAudioTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertNil(labels[@"media_audio_track"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedAudioTrack
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"FR");
        return YES;
    }];
    
    self.mediaPlayerController.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"fr"];
        }];
        return [audioOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultAudioOption;
    };
    
    [self playURL:OnDemandMultiAudioTracksTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"FR");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedAudioTrackDuringEntirePlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"DE");
        return YES;
    }];
    
    self.mediaPlayerController.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"de"];
        }];
        return [audioOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultAudioOption;
    };
    
    [self playURL:OnDemandMultiAudioTracksTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_audio_track"], @"DE");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_audio_track"], @"DE");
            playReceived = YES;
        }
        return seekReceived && playReceived;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"eof");
        XCTAssertEqualObjects(labels[@"media_audio_track"], @"DE");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testSelectedSegmentPlayback
{
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"start");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentReceived && playReceived;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testInitialSegmentSelectionAndPlayback
{
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"start");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentReceived && playReceived;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPrepareInitialSegmentSelectionAndPlayAndReset
{
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self prepareToPlayURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] completionHandler:^{
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"start");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionAfterStartOnFullLength
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"1");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"click");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingSelectedSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"100");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"click");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"100");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingNonSelectedSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"52");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:52.] withSegments:@[segment1, segment2]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];

    __block BOOL seekReceived = NO;
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"52");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"100");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"click");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"100");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTransitionFromSelectedSegmentIntoNonSelectedContiguousSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSegmentRepeatedSelection
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"click");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);

            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutsideSelectedSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"70");
            playReceived = YES;
        }
        return seekReceived && seekReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeMakeWithSeconds(70., NSEC_PER_SEC)] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL segmentSeekReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(segmentSeekReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segmentSeekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"53");
            segmentPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentSeekReceived && segmentPlayReceived;
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTAssertNotEqualObjects(event, @"segment");
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeMakeWithSeconds(53., NSEC_PER_SEC)] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSelectedSegmentAtStreamEnd
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"1795");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"start");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"1795");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentReceived && playReceived;
    }];
    
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"eof");
        XCTAssertEqualObjects(labels[@"media_position"], @"1800");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"51");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"60");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            fullLengthSeekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"60");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return fullLengthSeekReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:55.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    __block BOOL playAt50Received = NO;
    __block BOOL seekAt50Received = NO;
    __block BOOL playAt60Received = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            if ([labels[@"media_position"] isEqualToString:@"50"]) {
                XCTAssertFalse(seekAt50Received);
                XCTAssertFalse(playAt60Received);
                
                playAt50Received = YES;
            }
            else if ([labels[@"media_position"] isEqualToString:@"60"]) {
                playAt60Received = YES;
            }
            else {
                XCTFail(@"Unexpected event %@", event);
            }
        }
        else if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(playAt60Received);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            
            seekAt50Received = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return playAt50Received && seekAt50Received && playAt60Received;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            XCTAssertEqualObjects(labels[@"media_position"], @"5");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && playReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileIdle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePreparing
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePlaying
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
}

- (void)testDisableTrackingWhilePlayingSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePaused
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileSeeking
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthStopReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthStopReceived);
            fullLengthSeekReceived = YES;
        }
        else if ([event isEqualToString:@"stop"]) {
            fullLengthStopReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return fullLengthSeekReceived && fullLengthStopReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePausedInSegment
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparing
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparingToPlaySegment
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            XCTAssertEqualObjects(labels[@"segment_change_origin"], @"start");
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return segmentReceived && playReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlaying
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlayingSegment
{
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTAssertNotEqualObjects(event, @"segment");
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testEnableTrackingWhileSeeking
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block BOOL fullLengthPlayReceived = NO;
    __block BOOL fullLengthSeekReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            fullLengthPlayReceived = YES;
        }
        else if ([event isEqualToString:@"seek"]) {
            fullLengthSeekReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return fullLengthPlayReceived && fullLengthSeekReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePaused
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL playReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            XCTAssertFalse(pauseReceived);
            playReceived = YES;
        }
        else if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(pauseReceived);
            pauseReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
        return playReceived && pauseReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingTwiceWhilePlaying
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger stopEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"stop"]) {
            ++stopEventCount;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    self.mediaPlayerController.tracked = NO;
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:endEventObserver];
    }];
    
    XCTAssertEqual(stopEventCount, 1);
}

- (void)testEnableTrackingTwiceWhilePlaying
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger playEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"play"]) {
            ++playEventCount;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    self.mediaPlayerController.tracked = YES;
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:endEventObserver];
    }];
    
    XCTAssertEqual(playEventCount, 1);
}

- (void)testOnDemandHeartbeatPlayPausePlay
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger heartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 0);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
}

- (void)testLivestreamHeartbeatPlay
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertTrue(([labels[@"media_position"] integerValue] % 3) == 0);
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTAssertTrue(([labels[@"media_position"] integerValue] % 6) == 0);
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
            ++liveHeartbeatCount;
        }
    }];
    
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 2);
}

- (void)testHeartbeatWithInitialSegmentSelectionAndPlayback
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(4., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    Segment *updatedSegment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(4., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    self.mediaPlayerController.segments = @[updatedSegment];
    
    __block NSInteger heartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
    }];
    
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
}

- (void)testHeartbeatWithSegmentSelectionAfterStartOnFullLength
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL segmentReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"segment"]) {
            XCTAssertFalse(segmentReceived);
            XCTAssertFalse(playReceived);
            segmentReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        return seekReceived && segmentReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    Segment *updatedSegment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    self.mediaPlayerController.segments = @[updatedSegment];
    
    __block NSInteger heartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
    }];
    
    [self expectationForElapsedTimeInterval:13. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
}

- (void)testDVRLiveHeartbeats
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:DVRTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount;
        }
    }];
    
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 2);
}

- (void)testDVRTimeshiftHeartbeats
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:DVRTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    CMTime seekTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount;
        }
    }];
    
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 0);
}

- (void)testHeartbeatAfterDisablingTracking
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger heartbeatCount1 = 0;
    __block NSInteger liveHeartbeatCount1 = 0;
    id heartbeatEventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount1;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount1;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver1];
    }];
    
    XCTAssertEqual(heartbeatCount1, 2);
    XCTAssertEqual(liveHeartbeatCount1, 1);
    
    self.mediaPlayerController.tracked = NO;
    
    __block NSInteger heartbeatCount2 = 0;
    __block NSInteger liveHeartbeatCount2 = 0;
    id heartbeatEventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount2;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount2;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver2];
    }];
    
    XCTAssertEqual(heartbeatCount2, 0);
    XCTAssertEqual(liveHeartbeatCount2, 0);
}

- (void)testHeartbeatAfterEnablingTracking
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self playURL:LiveTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block NSInteger heartbeatCount1 = 0;
    __block NSInteger liveHeartbeatCount1 = 0;
    id heartbeatEventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount1;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount1;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver1];
    }];
    
    XCTAssertEqual(heartbeatCount1, 0);
    XCTAssertEqual(liveHeartbeatCount1, 0);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    __block NSInteger heartbeatCount2 = 0;
    __block NSInteger liveHeartbeatCount2 = 0;
    id heartbeatEventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerHeartbeatNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount2;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount2;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver2];
    }];
    
    XCTAssertEqual(heartbeatCount2, 2);
    XCTAssertEqual(liveHeartbeatCount2, 1);
}

- (void)testMetadata
{
    XCTAssertNil(self.mediaPlayerController.userInfo);
    XCTAssertNil(self.mediaPlayerController.analyticsLabels);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full" };
    
    NSDictionary *userInfo = @{ @"key" : @"value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:userInfo];
    XCTAssertEqualObjects([self.mediaPlayerController.userInfo dictionaryWithValuesForKeys:userInfo.allKeys], userInfo);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAnalyticsLabelsUpdates
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [event isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"custom_key" : @"custom_value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if (! [event isEqualToString:@"pause"]) {
            return NO;
        }
        
        XCTAssertNil(labels[@"custom_key"]);
        XCTAssertEqualObjects(labels[@"other_custom_key"], @"other_custom_value");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *updatedAnalyticsLabels = [[SRGAnalyticsStreamLabels alloc] init];
    updatedAnalyticsLabels.customInfo = @{ @"other_custom_key" : @"other_custom_value" };
    
    self.mediaPlayerController.analyticsLabels = updatedAnalyticsLabels;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAnalyticsLabelsIndirectChangeResilience
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [event isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"custom_key" : @"custom_value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if (! [event isEqualToString:@"pause"]) {
            return NO;
        }
        
        XCTAssertNil(labels[@"updated_key"]);
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    labels.customInfo = @{ @"updated_key" : @"updated_value" };
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackRateAtStart
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return YES;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackRateChange
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"1");
        return YES;
    }];
    
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return YES;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackRateAfterRestart
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return YES;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL stopReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            XCTAssertFalse(playReceived);
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            playReceived = YES;
        }
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return stopReceived && playReceived;
    }];
    
    [self.mediaPlayerController stop];
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackRateAfterReplay
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return YES;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self playURL:OnDemandTestURL() atPosition:nil withSegments:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return [event isEqualToString:@"eof"];
    }];
    
    CMTime seekTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(2., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"media_playback_rate"], @"0.5");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
