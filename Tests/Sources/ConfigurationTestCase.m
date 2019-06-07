//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

@interface ConfigurationTestCase : XCTestCase

@end

@implementation ConfigurationTestCase

#pragma mark Tests

- (void)testCreation
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqual(configuration.container, 7);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, @"comscore-vsite");
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, @"netmetrix-identifier");
}

- (void)testBusinessUnitSpecificConfiguration
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.centralized = NO;
    
    XCTAssertFalse(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3667);
    XCTAssertEqual(configuration.container, 7);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, @"comscore-vsite");
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, @"netmetrix-identifier");
}

- (void)testUnitTestingConfiguration
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.unitTesting = YES;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertTrue(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqual(configuration.container, 7);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, @"comscore-vsite");
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, @"netmetrix-identifier");
}

- (void)testCopy
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.centralized = YES;
    configuration.unitTesting = YES;
    
    SRGAnalyticsConfiguration *configurationCopy = [configuration copy];
    XCTAssertEqual(configuration.centralized, configurationCopy.centralized);
    XCTAssertEqual(configuration.unitTesting, configurationCopy.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, configurationCopy.businessUnitIdentifier);
    XCTAssertEqual(configuration.site, configurationCopy.site);
    XCTAssertEqual(configuration.container, configurationCopy.container);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, configurationCopy.comScoreVirtualSite);
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, configurationCopy.netMetrixIdentifier);
}

@end
