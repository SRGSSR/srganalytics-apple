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
}

@end
