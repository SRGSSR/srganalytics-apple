//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGContentProtection/SRGContentProtection.h>

/**
 *  Tests for common media flavors. Almost no livestream tests are made (since almost all of them require FairPlay).
 */
@interface MediaTestCase : XCTestCase

@end

@implementation MediaTestCase

#pragma mark Helpers

- (void)playMediaWithURN:(NSString *)URN
{
    SRGMediaPlayerController *controller = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        [controller playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

#pragma mark RSI tests

- (void)testTokenProtectedOnDemandVideoRSI
{
    if (SRGContentProtectionIsPublic()) {
        NSLog(@"Test disabled. Test stream not available in a public setup.");
        return;
    }
    
    [self playMediaWithURN:@"urn:rsi:video:11498675"];
}

- (void)testUnprotectedOnDemandAudioRSI
{
    [self playMediaWithURN:@"urn:rsi:audio:11398281"];
}

- (void)testDVRAudioLivestreamRSI
{
    [self playMediaWithURN:@"urn:rsi:audio:livestream_ReteUno"];
}

#pragma mark RTS tests

- (void)testUnprotectedOnDemandVideoRTS
{
    [self playMediaWithURN:@"urn:rts:video:10246693"];
}

- (void)testUnprotectedOnDemand360VideoRTS
{
    [self playMediaWithURN:@"urn:rts:video:8414077"];
}

- (void)testTokenProtectedOnDemandVideoRTS
{
    if (SRGContentProtectionIsPublic()) {
        NSLog(@"Test disabled. Test stream not available in a public setup.");
        return;
    }
    
    [self playMediaWithURN:@"urn:rts:video:10260786"];
}

- (void)testUnprotectedVideoLivestreamRTS
{
    [self playMediaWithURN:@"urn:rts:video:8841634"];
}

- (void)testUnprotectedOnDemandAudioRTS
{
    [self playMediaWithURN:@"urn:rts:audio:3813035"];
}

- (void)testDVRAudioLivestreamRTS
{
    [self playMediaWithURN:@"urn:rts:audio:3262320"];
}

#pragma mark RTR tests

- (void)testUnprotectedOnDemandVideoRTR
{
    [self playMediaWithURN:@"urn:rtr:video:5ba864ed-a6a2-407f-a84a-5c881be72c1a"];
}

- (void)testUnprotectedOnDemandAudioRTR
{
    [self playMediaWithURN:@"urn:rtr:audio:7607638e-15b9-4f2a-98ec-0ad41779279f"];
}

- (void)testGeoblockedAudioRTR
{
    [self playMediaWithURN:@"urn:rtr:audio:4b1c4f1f-eedd-4cf3-baa5-abac7a0359b4"];
}

- (void)testDVRAudioLivestreamRTR
{
    [self playMediaWithURN:@"urn:rtr:audio:a029e818-77a5-4c2e-ad70-d573bb865e31"];
}

#pragma mark SRF tests

- (void)testUnprotectedOnDemandVideoSRF
{
    [self playMediaWithURN:@"urn:srf:video:1ea90dc7-8509-4bfd-aac2-061b8823de5f"];
}

- (void)testUnprotectedOnDemandAudioSRF
{
    [self playMediaWithURN:@"urn:srf:audio:b960f717-92b8-4db9-8b6f-5e01293d8bb9"];
}

- (void)testDVRAudioLivestreamSRF
{
    [self playMediaWithURN:@"urn:srf:audio:69e8ac16-4327-4af4-b873-fd5cd6e895a7"];
}

#pragma mark SWI tests

- (void)testUnprotectedOnDemandVideoSWI
{
    [self playMediaWithURN:@"urn:swi:video:44668294"];
}

@end
