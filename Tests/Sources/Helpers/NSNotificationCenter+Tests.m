//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *type = labels[@"hit_type"];
        if ([type isEqualToString:@"screen"] || [type isEqualToString:@"buffer"] || [type isEqualToString:@"seek"] || [type isEqualToString:@"pos"] || [type isEqualToString:@"uptime"]) {
            return;
        }
        
        block(type, labels);
    }];
}

- (id<NSObject>)addObserverForComScoreHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return;
        }
        
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return;
        }
        
        block(event, labels);
    }];
}

@end
