//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

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
    XCTAssertFalse(settings.DRM);
    XCTAssertEqual(settings.startBitRate, SRGDefaultStartBitRate);
    XCTAssertNil(settings.sourceUid);
}

- (void)testCustomSettings
{
    SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
    settings.streamingMethod = SRGStreamingMethodHLS;
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.DRM = YES;
    settings.startBitRate = 1200;
    settings.sourceUid = @"Source unique id";
    
    XCTAssertEqual(settings.streamingMethod, SRGStreamingMethodHLS);
    XCTAssertEqual(settings.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settings.quality, SRGQualityHD);
    XCTAssertTrue(settings.DRM);
    XCTAssertEqual(settings.startBitRate, 1200);
    XCTAssertEqual(settings.sourceUid, @"Source unique id");
}

- (void)testCopy
{
    SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
    settings.streamingMethod = SRGStreamingMethodHLS;
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.DRM = YES;
    settings.startBitRate = 1200;
    settings.sourceUid = @"Source unique id";
    
    // Make a copy
    SRGPlaybackSettings *settingsCopy = [settings copy];
    
    // Modify the original
    settings.streamingMethod = SRGStreamingMethodNone;
    settings.streamType = SRGStreamTypeNone;
    settings.quality = SRGQualityNone;
    settings.DRM = NO;
    settings.startBitRate = SRGDefaultStartBitRate;
    settings.sourceUid = @"Another source unique id";
    
    // Check that the copy is identical to the original
    XCTAssertEqual(settingsCopy.streamingMethod, SRGStreamingMethodHLS);
    XCTAssertEqual(settingsCopy.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settingsCopy.quality, SRGQualityHD);
    XCTAssertTrue(settingsCopy.DRM);
    XCTAssertEqual(settingsCopy.startBitRate, 1200);
    XCTAssertEqual(settingsCopy.sourceUid, @"Source unique id");
}

@end
