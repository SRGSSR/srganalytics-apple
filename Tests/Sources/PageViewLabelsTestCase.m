//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import "SRGAnalyticsLabels+Private.h"

@interface PageViewLabelsTestCase : XCTestCase

@end

@implementation PageViewLabelsTestCase

#pragma mark Tests

- (void)testEmpty
{
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    XCTAssertNotNil(labels.labelsDictionary);
    XCTAssertEqual(labels.labelsDictionary.count, 0);
}

- (void)testNonEmpty
{
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"key" : @"value" };
    XCTAssertEqualObjects(labels.labelsDictionary, labels.customInfo);
}

- (void)testEquality
{
    SRGAnalyticsPageViewLabels *labels1 = [[SRGAnalyticsPageViewLabels alloc] init];
    labels1.customInfo = @{ @"key" : @"value" };
    XCTAssertEqualObjects(labels1, labels1);
    
    SRGAnalyticsPageViewLabels *labels2 = [[SRGAnalyticsPageViewLabels alloc] init];
    labels2.customInfo = @{ @"key" : @"value" };
    XCTAssertEqualObjects(labels1, labels2);
    
    SRGAnalyticsPageViewLabels *labels3 = [[SRGAnalyticsPageViewLabels alloc] init];
    labels3.customInfo = @{ @"other_key" : @"other_value" };
    XCTAssertNotEqualObjects(labels1, labels3);
}

- (void)testCopy
{
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"key" : @"value" };
    
    SRGAnalyticsPageViewLabels *labelsCopy = [labels copy];
    XCTAssertEqualObjects(labels, labelsCopy);
}

@end
