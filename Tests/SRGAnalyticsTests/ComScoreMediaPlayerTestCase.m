//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "Segment.h"
#import "XCTestCase+Tests.h"

@import SRGAnalyticsMediaPlayer;
@import ComScore;

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"];
}

@interface ComScoreMediaPlayerTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreMediaPlayerTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    self.mediaPlayerController.liveTolerance = 10.;
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackToEnd
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1795);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1800);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testReplay
{
    __block NSString *sessionUid1 = nil;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        
        XCTAssertNotNil(labels[@"ns_st_id"]);
        sessionUid1 = labels[@"ns_st_id"];
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_id"], sessionUid1);
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        
        if (! [event isEqualToString:@"end"]) {
            return NO;
        }
        
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1800);
        return YES;
    }];
    
    SRGPosition *position = [SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController seekToPosition:position withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSString *sessionUid2 = nil;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        
        XCTAssertNotNil(labels[@"ns_st_id"]);
        sessionUid2 = labels[@"ns_st_id"];
        XCTAssertNotEqualObjects(sessionUid1, sessionUid2);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"ns_st_id"], sessionUid2);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayPauseSeekPause
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        if (playbackState == SRGMediaPlayerPlaybackStateSeeking) {
            XCTAssertFalse(pauseReceived);
            seekReceived = YES;
        }
        else if (playbackState == SRGMediaPlayerPlaybackStatePaused) {
            pauseReceived = YES;
        }
        return seekReceived && pauseReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testPlayPausePlay
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
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
    __block NSString *sessionUid1 = nil;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full1");
        XCTAssertNotNil(labels[@"ns_st_id"]);
        sessionUid1 = labels[@"ns_st_id"];
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels1 = [[SRGAnalyticsStreamLabels alloc] init];
    labels1.comScoreCustomInfo = @{ @"stream_name" : @"full1" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels1 userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full1");
        XCTAssertEqualObjects(labels[@"ns_st_id"], sessionUid1);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels2 = [[SRGAnalyticsStreamLabels alloc] init];
    labels2.comScoreCustomInfo = @{ @"stream_name" : @"full2" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:labels2 userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSString *sessionUid2 = nil;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full2");
        XCTAssertNotNil(labels[@"ns_st_id"]);
        sessionUid2 = labels[@"ns_st_id"];
        XCTAssertNotEqualObjects(sessionUid1, sessionUid2);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full2");
        XCTAssertEqualObjects(labels[@"ns_st_id"], sessionUid2);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testWithoutLabels
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testMediaError
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://httpbin.org/status/403"] atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testCommonLabels
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"ns_st_mv"], SRGMediaPlayerMarketingVersion());
        XCTAssertEqualObjects(labels[@"ns_st_it"], @"c");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLivePlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"7150000");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"7150000");
        return YES;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(45., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"45000");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"7150000");
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"45000");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"7150000");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveStopLive
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when paused");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_ldw"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testInitialSegmentSelectionAndPlaythrough
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPrepareInitialSegmentSelectionAndPlayAndReset
{
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil completionHandler:^{
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionAfterStartOnFullLength
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(pauseReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 100);
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingNonSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 52);
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:52.] withSegments:@[segment1, segment2] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(pauseReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 52);
            pauseReceived = YES;
        }
        else if ([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 100);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTransitionFromSelectedSegmentIntoNonSelectedContiguousSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 20);
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSegmentRepeatedSelection
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutsideSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 70);
            
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeMakeWithSeconds(70., NSEC_PER_SEC)] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 53);
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeMakeWithSeconds(53., NSEC_PER_SEC)] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentAtStreamEnd
{
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1795);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 1800);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 51);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 60);
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 60);
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:55.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 60);
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPauseReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 5);
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileIdle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePreparing
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"end");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
}

- (void)testDisableTrackingWhilePlayingSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePaused
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"end");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileSeeking
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthEndReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthEndReceived);
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"end"]) {
            fullLengthEndReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthEndReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePausedInSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparing
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparingToPlaySegment
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlaying
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlayingSegment
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 2);
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhileSeeking
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePaused
{
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL playReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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

- (void)testDisableTwiceTrackingWhilePlaying
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger endEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            ++endEventCount;
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
    
    XCTAssertEqual(endEventCount, 1);
}

- (void)testEnableTrackingTwiceWhilePlaying
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full" };
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block NSInteger playEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
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

@end
