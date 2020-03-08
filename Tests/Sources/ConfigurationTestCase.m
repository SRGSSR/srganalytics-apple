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
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, @"preprod");
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
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, @"preprod");
}

- (void)testEnvironmentModePreProduction
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.environmentMode = SRGAnalyticsEnvironmentModePreProduction;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqual(configuration.container, 7);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, @"comscore-vsite");
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, @"netmetrix-identifier");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModePreProduction);
    XCTAssertEqualObjects(configuration.environment, @"preprod");
}

- (void)testEnvironmentModeProduction
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.environmentMode = SRGAnalyticsEnvironmentModeProduction;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqual(configuration.container, 7);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, @"comscore-vsite");
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, @"netmetrix-identifier");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeProduction);
    XCTAssertEqualObjects(configuration.environment, @"prod");
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
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, @"preprod");
}

- (void)testCopy
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:7
                                                                                             comScoreVirtualSite:@"comscore-vsite"
                                                                                             netMetrixIdentifier:@"netmetrix-identifier"];
    configuration.centralized = YES;
    configuration.unitTesting = YES;
    
    SRGAnalyticsConfiguration *configurationCopy = configuration.copy;
    XCTAssertEqual(configuration.centralized, configurationCopy.centralized);
    XCTAssertEqual(configuration.unitTesting, configurationCopy.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, configurationCopy.businessUnitIdentifier);
    XCTAssertEqual(configuration.site, configurationCopy.site);
    XCTAssertEqual(configuration.container, configurationCopy.container);
    XCTAssertEqualObjects(configuration.comScoreVirtualSite, configurationCopy.comScoreVirtualSite);
    XCTAssertEqualObjects(configuration.netMetrixIdentifier, configurationCopy.netMetrixIdentifier);
    XCTAssertEqual(configuration.environmentMode, configurationCopy.environmentMode);
    XCTAssertEqualObjects(configuration.environment, configurationCopy.environment);
}

@end
