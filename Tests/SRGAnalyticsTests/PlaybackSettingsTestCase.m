//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

@import SRGAnalyticsDataProvider;

@interface PlaybackSettingsTestCase : XCTestCase

@end

@implementation PlaybackSettingsTestCase

#pragma mark Tests

- (void)testDefaultSettings
{
    SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
    XCTAssertEqual(settings.streamingMethod, SRGStreamingMethodNone);
    XCTAssertEqual(settings.streamType, SRGStreamTypeNone);
    XCTAssertEqual(settings.quality, SRGQualityNone);
    XCTAssertNil(settings.sourceUid);
}

- (void)testCustomSettings
{
    SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
    settings.streamingMethod = SRGStreamingMethodHLS;
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.sourceUid = @"Source unique id";
    
    XCTAssertEqual(settings.streamingMethod, SRGStreamingMethodHLS);
    XCTAssertEqual(settings.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settings.quality, SRGQualityHD);
    XCTAssertEqual(settings.sourceUid, @"Source unique id");
}

- (void)testCopy
{
    SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
    settings.streamingMethod = SRGStreamingMethodHLS;
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.sourceUid = @"Source unique id";
    
    // Make a copy
    SRGPlaybackSettings *settingsCopy = settings.copy;
    
    // Modify the original
    settings.streamingMethod = SRGStreamingMethodNone;
    settings.streamType = SRGStreamTypeNone;
    settings.quality = SRGQualityNone;
    settings.sourceUid = @"Another source unique id";
    
    // Check that the copy is identical to the original
    XCTAssertEqual(settingsCopy.streamingMethod, SRGStreamingMethodHLS);
    XCTAssertEqual(settingsCopy.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settingsCopy.quality, SRGQualityHD);
    XCTAssertEqual(settingsCopy.sourceUid, @"Source unique id");
}

@end
