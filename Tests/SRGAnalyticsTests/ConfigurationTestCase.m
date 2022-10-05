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
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqualObjects(configuration.sourceKey, @"source-key");
    XCTAssertEqualObjects(configuration.siteName, @"site-name");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, SRGAnalyticsEnvironmentPreProduction);
}

- (void)testBusinessUnitSpecificConfiguration
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    configuration.centralized = NO;
    
    XCTAssertFalse(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3667);
    XCTAssertEqualObjects(configuration.sourceKey, @"source-key");
    XCTAssertEqualObjects(configuration.siteName, @"site-name");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, SRGAnalyticsEnvironmentPreProduction);
}

- (void)testEnvironmentModePreProduction
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    configuration.environmentMode = SRGAnalyticsEnvironmentModePreProduction;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqualObjects(configuration.sourceKey, @"source-key");
    XCTAssertEqualObjects(configuration.siteName, @"site-name");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModePreProduction);
    XCTAssertEqualObjects(configuration.environment, SRGAnalyticsEnvironmentPreProduction);
}

- (void)testEnvironmentModeProduction
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    configuration.environmentMode = SRGAnalyticsEnvironmentModeProduction;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertFalse(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqualObjects(configuration.sourceKey, @"source-key");
    XCTAssertEqualObjects(configuration.siteName, @"site-name");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeProduction);
    XCTAssertEqualObjects(configuration.environment, @"prod");
}

- (void)testUnitTestingConfiguration
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    configuration.unitTesting = YES;
    
    XCTAssertTrue(configuration.centralized);
    XCTAssertTrue(configuration.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, SRGAnalyticsBusinessUnitIdentifierSRF);
    XCTAssertEqual(configuration.site, 3666);
    XCTAssertEqualObjects(configuration.sourceKey, @"source-key");
    XCTAssertEqualObjects(configuration.siteName, @"site-name");
    XCTAssertEqual(configuration.environmentMode, SRGAnalyticsEnvironmentModeAutomatic);
    XCTAssertEqualObjects(configuration.environment, SRGAnalyticsEnvironmentPreProduction);
}

- (void)testCopy
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"site-name"];
    configuration.centralized = YES;
    configuration.unitTesting = YES;
    
    SRGAnalyticsConfiguration *configurationCopy = configuration.copy;
    XCTAssertEqual(configuration.centralized, configurationCopy.centralized);
    XCTAssertEqual(configuration.unitTesting, configurationCopy.unitTesting);
    XCTAssertEqualObjects(configuration.businessUnitIdentifier, configurationCopy.businessUnitIdentifier);
    XCTAssertEqual(configuration.site, configurationCopy.site);
    XCTAssertEqualObjects(configuration.sourceKey, configurationCopy.sourceKey);
    XCTAssertEqualObjects(configuration.siteName, configurationCopy.siteName);
    XCTAssertEqual(configuration.environmentMode, configurationCopy.environmentMode);
    XCTAssertEqualObjects(configuration.environment, configurationCopy.environment);
}

@end
