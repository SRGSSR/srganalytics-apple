//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static NSURL *ServiceTestURL(void)
{
    return SRGIntegrationLayerProductionServiceURL();
}

@interface ComScoreDataProviderTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreDataProviderTestCase

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
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualityHD;
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:settings userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
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
}

- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"10vor10 vom 06.09.2018");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"SD");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualitySD;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
}

@end
