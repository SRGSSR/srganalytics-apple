//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

// Private header
#import "SRGAnalyticsLabels+Private.h"
#import "SRGResource+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static NSURL *ServiceTestURL(void)
{
    return SRGIntegrationLayerProductionServiceURL();
}

static NSURL *MMFTestURL(void)
{
    return [NSURL URLWithString:@"https://play-mmf.herokuapp.com/integrationlayer"];
}

@interface DataProviderTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation DataProviderTestCase

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

- (void)testPrepareToPlayMediaComposition
{
    // Prepare playback. An opening play event must be received
    __block BOOL playReceived = NO;
    __block BOOL pauseReceived = NO;
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([labels[@"event_id"] isEqualToString:@"play"]) {
            XCTAssertFalse(pauseReceived);
            playReceived = YES;
        }
        else if ([labels[@"event_id"] isEqualToString:@"pause"]) {
            pauseReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"media_segment"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        
        return playReceived && pauseReceived;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamType = SRGStreamTypeDVR;
        settings.quality = SRGQualityHD;
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:settings userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            XCTAssertEqual(self.mediaPlayerController.resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertEqual(self.mediaPlayerController.resource.quality, SRGQualityHD);
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPrepareToPlay360Video
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPrepareToPlay360VideoAlreadyStereoscopic
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.view.viewMode = SRGMediaPlayerViewModeStereoscopic;
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeStereoscopic);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaComposition
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Zwangsheirat – mitten unter uns");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:c825d897-9631-41d9-bc20-33f02c03f760");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c825d897-9631-41d9-bc20-33f02c03f760" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.segments.count, fetchedMediaComposition.mainChapter.segments.count);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlayLivestreamInMediaComposition
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Livestream");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:rts:video:8841634");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8841634" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertNil(self.mediaPlayerController.segments);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlay360InMediaComposition
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:rts:video:8414077");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
}

- (void)testPlay360AndFlatInMediaComposition
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_gothard" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition1);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
    
    __block BOOL stopReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition2 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_balloon_360" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition2 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition2);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
    
    stopReceived = NO;
    playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    self.mediaPlayerController.view.viewMode = SRGMediaPlayerViewModeStereoscopic;
    
    __block SRGMediaComposition *fetchedMediaComposition3 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_gothard" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition3 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition3);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeStereoscopic);
    
    stopReceived = NO;
    playReceived = NO;
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition4 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:10254787" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition4 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition4);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testMetadata
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:a2c7ad8b-026d-4696-9934-ade687497a82" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        NSDictionary *userInfo = @{ @"key" : @"value" };
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:userInfo completionHandler:^{
            XCTAssertEqualObjects([self.mediaPlayerController.userInfo dictionaryWithValuesForKeys:userInfo.allKeys], userInfo);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithCompatibleMediaComposition
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block NSString *originalTitle = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    NSDate *startDate = NSDate.date;
    NSDate *endDate = [startDate dateByAddingTimeInterval:200];
    NSString *URN = [NSString stringWithFormat:@"urn:rts:video:_bipbop_advanced_delay_%@_%@", @((NSInteger)[startDate timeIntervalSince1970]), @((NSInteger)[endDate timeIntervalSince1970])];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        originalTitle = mediaComposition.mainChapter.title;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // The test media title changes over time. Wait a little bit to detect a change.
    [self expectationForElapsedTimeInterval:2. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertNotEqualObjects(self.mediaPlayerController.mediaComposition.mainChapter.title, originalTitle);
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithoutMediaComposition
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:a2c7ad8b-026d-4696-9934-ade687497a82" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    self.mediaPlayerController.mediaComposition = nil;
    XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition.mainChapter.segments);
}

- (void)testMediaCompositionUpdateWithDifferentChapter
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:a2c7ad8b-026d-4696-9934-ade687497a82" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:895b9096-f07d-4daa-83e0-ac6486ac72e3" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        
        // Incompatible media composition. No update must have taken place
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, fetchedMediaComposition1);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaCompositionUpdateWithDifferentMainSegment
{
    // Retrieve two media compositions of segments belonging to the same media composition
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8995306" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8995308" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, mediaComposition.mainChapter.segments);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaCompositionUpdateWithNewSegment
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    NSDate *startDate = [NSDate.date dateByAddingTimeInterval:-6];
    NSDate *endDate = [startDate dateByAddingTimeInterval:20];
    NSString *URN = [NSString stringWithFormat:@"urn:rts:video:_tagesschau24_ard_fulldvr_%@_%@", @((NSInteger)[startDate timeIntervalSince1970]), @((NSInteger)[endDate timeIntervalSince1970])];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
    
    // The full DVR adds a highlight every 5 seconds. Wait a little bit to detect a change.
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        XCTAssertTrue(fetchedMediaComposition1.mainChapter.segments.count != mediaComposition.mainChapter.segments.count);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, mediaComposition.mainChapter.segments);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDefaultStreamingMethod
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPreferredStreamingMethod
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamingMethod = SRGStreamingMethodProgressive;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodProgressive);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonExistingStreamingMethod
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamingMethod = SRGStreamingMethodHTTP;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoDRMPreferenceWithHybridStream
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_drm18_special_3" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertFalse(resource.srg_requiresDRM);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDRMPreferenceWithHybridStream
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_drm18_special_3" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.DRM = YES;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertTrue(resource.srg_requiresDRM);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoDRMPreferenceWithDRMStream
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_drm18" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertTrue(resource.srg_requiresDRM);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDRMPreferenceWithStandardStream
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.DRM = YES;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertTrue(resource.srg_requiresDRM);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDRMPreferenceWithDASHResource
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_drm18" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamingMethod = SRGStreamingMethodDASH;
        settings.DRM = YES;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamingMethod, SRGStreamingMethodDASH);
            XCTAssertTrue(resource.srg_requiresDRM);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDefaultStreamType
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamType, SRGStreamTypeDVR);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPreferredStreamType
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamType = SRGStreamTypeLive;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamType, SRGStreamTypeLive);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonExistingStreamType
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.streamType = SRGStreamTypeOnDemand;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.streamType, SRGStreamTypeDVR);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDefaultQuality
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.quality, SRGQualityHD);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPreferredQuality
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualitySD;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.quality, SRGQualitySD);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonExistingQuality
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualityHQ;
        
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:settings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqual(resource.quality, SRGQualityHD);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPreferHTTPSResources
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    // The following audio has two equivalent resources for the playback default settings (one in HTTP, the other in HTTPS). The order of these resources in the JSON is not reliable,
    // but we want to select always the HTTPS resource first
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:audio:d7dd9454-23c8-4160-81ff-ace459dd53c0" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertEqualObjects(resource.URL.scheme, @"https");
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVideoAnalyticsLabels
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertNotEqual(analyticsLabels.labelsDictionary.count, 0);
            XCTAssertNotEqual(analyticsLabels.comScoreLabelsDictionary.count, 0);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAudioAnalyticsLabels
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition retrieved"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        BOOL success = [mediaComposition playbackContextWithPreferredSettings:nil contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
            XCTAssertNotEqual(analyticsLabels.labelsDictionary.count, 0);
            XCTAssertEqual(analyticsLabels.comScoreLabelsDictionary.count, 0);
        }];
        XCTAssertTrue(success);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaCompositionWithSourceUid
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        XCTAssertEqualObjects(labels[@"source_id"], @"SWI source unique id");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
        playbackSettings.sourceUid = @"SWI source unique id";
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaySegmentInMediaCompositionWithSourceUid
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43");
        XCTAssertEqualObjects(labels[@"source_id"], @"SRF source unique id");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
        playbackSettings.sourceUid = @"SRF source unique id";
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekToSegmentInMediaCompositionWithSourceUid
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43");
        XCTAssertEqualObjects(labels[@"source_id"], @"SRF source unique id");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
        playbackSettings.sourceUid = @"SRF source unique id";
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGSegment.new, URN), @"urn:srf:video:802df764-3044-488e-aff0-fca3cdec85ff"];
    SRGSegment *segment = [fetchedMediaComposition.mainChapter.segments filteredArrayUsingPredicate:predicate].firstObject;
    XCTAssertNotNil(segment);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [labels[@"event_id"] isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:802df764-3044-488e-aff0-fca3cdec85ff");
        XCTAssertEqualObjects(labels[@"source_id"], @"SRF source unique id");
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:^(BOOL finished) {
        XCTAssertEqual(finished, YES);
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSwitchChapterInMediaCompositionWithSourceUid
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43");
        XCTAssertEqualObjects(labels[@"source_id"], @"SRF source unique id");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43" standalone:YES withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
        playbackSettings.sourceUid = @"SRF source unique id";
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, URN), @"urn:srf:video:802df764-3044-488e-aff0-fca3cdec85ff"];
    SRGChapter *chapter1 = [fetchedMediaComposition.chapters filteredArrayUsingPredicate:predicate1].firstObject;
    XCTAssertNotNil(chapter1);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [labels[@"event_id"] isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:802df764-3044-488e-aff0-fca3cdec85ff");
        XCTAssertEqualObjects(labels[@"source_id"], @"Another SRF source unique id");
        return YES;
    }];
    
    SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
    playbackSettings.sourceUid = @"Another SRF source unique id";
    [self.mediaPlayerController playMediaComposition:[fetchedMediaComposition mediaCompositionForSubdivision:chapter1] atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, URN), @"urn:srf:video:6ca4aaed-cc8a-4568-be5a-773afd20bbcf"];
    SRGChapter *chapter2 = [fetchedMediaComposition.chapters filteredArrayUsingPredicate:predicate2].firstObject;
    XCTAssertNotNil(chapter2);
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [labels[@"event_id"] isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:6ca4aaed-cc8a-4568-be5a-773afd20bbcf");
        XCTAssertNil(labels[@"source_id"]);
        return YES;
    }];
    
    [self.mediaPlayerController playMediaComposition:[fetchedMediaComposition mediaCompositionForSubdivision:chapter2] atPosition:nil withPreferredSettings:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateMediaCompositionWithSourceUid
{
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        XCTAssertEqualObjects(labels[@"source_id"], @"SWI source unique id");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
        playbackSettings.sourceUid = @"SWI source unique id";
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:playbackSettings userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Media composition updated"];
    
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        XCTAssertEqualObjects(labels[@"source_id"], @"SWI source unique id");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
