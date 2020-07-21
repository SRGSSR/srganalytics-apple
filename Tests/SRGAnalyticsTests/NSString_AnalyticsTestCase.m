//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+SRGAnalytics.h"

@import XCTest;

@interface NSString_AnalyticsTestCase : XCTestCase

@end

@implementation NSString_AnalyticsTestCase

#pragma mark Tests

- (void)testFormattedStrings
{
    XCTAssertEqualObjects(@"Ganz & Gloria".srg_comScoreFormattedString, @"ganz-and-gloria");
    XCTAssertEqualObjects(@"Hello, world!".srg_comScoreFormattedString, @"hello-world");
    XCTAssertEqualObjects(@"Strom: So speichern Akkus (7/8)".srg_comScoreFormattedString, @"strom-so-speichern-akkus-7-8");
    XCTAssertEqualObjects(@"SRGSSR".srg_comScoreFormattedString, @"srgssr");
    XCTAssertEqualObjects(@"     trimmed   ".srg_comScoreFormattedString, @"trimmed");
    XCTAssertEqualObjects(@"     trimmed!   ".srg_comScoreFormattedString, @"trimmed");
    XCTAssertEqualObjects(@"Vue aérienne de la zone de la \"potentielle attaque terroriste\" à Londres".srg_comScoreFormattedString, @"vue-aerienne-de-la-zone-de-la-potentielle-attaque-terroriste-a-londres");
    XCTAssertEqualObjects(@"News: \"Hello\"".srg_comScoreFormattedString, @"news-hello");
}

@end
