//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNotifications.h"

#import <objc/runtime.h>

@import TCCore;

static BOOL s_interceptorEnabled = NO;

NSString * const SRGAnalyticsRequestNotification = @"SRGAnalyticsRequestNotification";
NSString * const SRGAnalyticsLabelsKey = @"SRGAnalyticsLabels";

NSString * const SRGAnalyticsComScoreRequestNotification = @"SRGAnalyticsComScoreRequestNotification";
NSString * const SRGAnalyticsComScoreLabelsKey = @"SRGAnalyticsComScoreLabels";

static NSDictionary<NSString *, NSString *> *SRGAnalyticsProxyLabelsFromURLComponents(NSURLComponents *URLComponents)
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    [URLComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull queryItem, NSUInteger idx, BOOL * _Nonnull stop) {
        labels[queryItem.name] = [queryItem.value stringByRemovingPercentEncoding];
    }];
    return labels.copy;
}

@implementation NSURLSession (SRGAnalyticsProxy)

+ (void)srg_enableAnalyticsInterceptor
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(dataTaskWithRequest:completionHandler:)),
                                   class_getInstanceMethod(self, @selector(srganalytics_swizzled_dataTaskWithRequest:completionHandler:)));
}

- (NSURLSessionDataTask *)srganalytics_swizzled_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
{
    NSURL *URL = request.URL;
    NSString *host = URL.host;
    if ([host containsString:@"scorecardresearch"]) {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        [NSNotificationCenter.defaultCenter postNotificationName:SRGAnalyticsComScoreRequestNotification
                                                          object:nil
                                                        userInfo:@{ SRGAnalyticsComScoreLabelsKey : SRGAnalyticsProxyLabelsFromURLComponents(URLComponents) }];
        
    }
    return [self srganalytics_swizzled_dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

void SRGAnalyticsEnableRequestInterceptor(void)
{
    if (s_interceptorEnabled) {
        return;
    }
    
    [NSURLSession srg_enableAnalyticsInterceptor];

    [NSNotificationCenter.defaultCenter addObserverForName:kTCNotification_HTTPRequest object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSString *bodyString = notification.userInfo[kTCUserInfo_POSTData];
        NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary<NSString *, NSString *> *labelsDictionary = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:NULL];
        if (labelsDictionary) {
            [NSNotificationCenter.defaultCenter postNotificationName:SRGAnalyticsRequestNotification
                                                              object:nil
                                                            userInfo:@{ SRGAnalyticsLabelsKey : labelsDictionary }];
        }
    }];
    
    s_interceptorEnabled = YES;
}
