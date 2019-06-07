//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import "SRGAnalyticsLabels+Private.h"

@interface HiddenEventLabelsTestCase : XCTestCase

@end

@implementation HiddenEventLabelsTestCase

#pragma mark Tests

- (void)testEmpty
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    XCTAssertNotNil(labels.labelsDictionary);
    XCTAssertEqual(labels.labelsDictionary.count, 0);
}

- (void)testNonEmpty
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.type = @"type";
    labels.value = @"value";
    labels.source = @"source";
    labels.extraValue1 = @"extra_value1";
    labels.extraValue2 = @"extra_value2";
    labels.extraValue3 = @"extra_value3";
    labels.extraValue4 = @"extra_value4";
    labels.extraValue5 = @"extra_value5";
    labels.customInfo = @{ @"key" : @"value" };
    
    NSDictionary *labelsDictionary = @{ @"event_type" : @"type",
                                        @"event_value" : @"value",
                                        @"event_source" : @"source",
                                        @"event_value_1" : @"extra_value1",
                                        @"event_value_2" : @"extra_value2",
                                        @"event_value_3" : @"extra_value3",
                                        @"event_value_4" : @"extra_value4",
                                        @"event_value_5" : @"extra_value5",
                                        @"key" : @"value" };
    XCTAssertEqualObjects(labels.labelsDictionary, labelsDictionary);
}

- (void)testEquality
{
    SRGAnalyticsHiddenEventLabels *labels1 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels1.type = @"type";
    labels1.value = @"value";
    labels1.source = @"source";
    labels1.extraValue1 = @"extra_value1";
    labels1.extraValue2 = @"extra_value2";
    labels1.customInfo = @{ @"key" : @"value" };
    XCTAssertEqualObjects(labels1, labels1);
    
    SRGAnalyticsHiddenEventLabels *labels2 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels2.type = @"type";
    labels2.value = @"value";
    labels2.source = @"source";
    labels2.extraValue1 = @"extra_value1";
    labels2.extraValue2 = @"extra_value2";
    labels2.customInfo = @{ @"key" : @"value" };
    XCTAssertEqualObjects(labels1, labels2);
    
    SRGAnalyticsHiddenEventLabels *labels3 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels3.type = @"other_type";
    labels3.value = @"value";
    labels3.source = @"source";
    labels3.extraValue1 = @"extra_value1";
    labels3.extraValue2 = @"extra_value2";
    labels3.customInfo = @{ @"key" : @"value" };
    XCTAssertNotEqualObjects(labels1, labels3);
    
    SRGAnalyticsHiddenEventLabels *labels4 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels4.type = @"type";
    labels4.value = @"other_value";
    labels4.source = @"source";
    labels4.extraValue1 = @"extra_value1";
    labels4.extraValue2 = @"extra_value2";
    labels4.customInfo = @{ @"key" : @"value" };
    XCTAssertNotEqualObjects(labels1, labels4);
    
    SRGAnalyticsHiddenEventLabels *labels5 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels5.type = @"type";
    labels5.value = @"value";
    labels5.source = @"other_source";
    labels5.extraValue1 = @"extra_value1";
    labels5.extraValue2 = @"extra_value2";
    labels5.customInfo = @{ @"key" : @"value" };
    XCTAssertNotEqualObjects(labels1, labels5);
    
    SRGAnalyticsHiddenEventLabels *labels6 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels6.type = @"type";
    labels6.value = @"value";
    labels6.extraValue1 = @"other_extra_value1";
    labels6.extraValue2 = @"extra_value2";
    labels6.source = @"source";
    labels6.customInfo = @{ @"key" : @"value" };
    XCTAssertNotEqualObjects(labels1, labels6);
    
    SRGAnalyticsHiddenEventLabels *labels7 = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels7.type = @"type";
    labels7.value = @"value";
    labels7.source = @"source";
    labels7.extraValue1 = @"extra_value1";
    labels7.extraValue2 = @"extra_value2";
    labels7.customInfo = @{ @"other_key" : @"other_value" };
    XCTAssertNotEqualObjects(labels1, labels7);
}

- (void)testCopy
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.type = @"type";
    labels.value = @"value";
    labels.source = @"source";
    labels.extraValue1 = @"extra_value1";
    labels.extraValue2 = @"extra_value2";
    labels.customInfo = @{ @"key" : @"value" };
    
    SRGAnalyticsHiddenEventLabels *labelsCopy = [labels copy];
    XCTAssertEqualObjects(labels, labelsCopy);
}

- (void)testCustomInfoOverrides
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.type = @"type";
    labels.value = @"value";
    labels.source = @"source";
    labels.customInfo = @{ @"event_type" : @"overridden",
                           @"event_value" : @"overridden",
                           @"event_source" : @"overridden" };
    XCTAssertEqualObjects(labels.labelsDictionary, labels.customInfo);
}

@end
