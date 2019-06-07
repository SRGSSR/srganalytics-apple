//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNotifications.h"

#import <objc/runtime.h>

static BOOL s_interceptorEnabled = NO;

NSString * const SRGAnalyticsRequestNotification = @"SRGAnalyticsRequestNotification";
NSString * const SRGAnalyticsLabelsKey = @"SRGAnalyticsLabels";

NSString * const SRGAnalyticsComScoreRequestNotification = @"SRGAnalyticsComScoreRequestNotification";
NSString * const SRGAnalyticsComScoreLabelsKey = @"SRGAnalyticsComScoreLabels";

NSString * const SRGAnalyticsNetmetrixRequestNotification = @"SRGAnalyticsNetmetrixRequestNotification";
NSString * const SRGAnalyticsNetmetrixURLKey = @"SRGAnalyticsNetmetrixURL";

static NSDictionary<NSString *, NSString *> *SRGAnalyticsProxyLabelsFromURLComponents(NSURLComponents *URLComponents)
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    [URLComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull queryItem, NSUInteger idx, BOOL * _Nonnull stop) {
        labels[queryItem.name] = [queryItem.value stringByRemovingPercentEncoding];
    }];
    return [labels copy];
}

@implementation NSURLSession (SRGAnalyticsProxy)

+ (void)srg_enableAnalyticsInterceptor
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(dataTaskWithRequest:completionHandler:)),
                                   class_getInstanceMethod(self, @selector(swizzled_dataTaskWithRequest:completionHandler:)));
}

- (NSURLSessionDataTask *)swizzled_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
{
    NSURL *URL = request.URL;
    NSString *host = URL.host;
    if ([host containsString:@"scorecardresearch"]) {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        [NSNotificationCenter.defaultCenter postNotificationName:SRGAnalyticsComScoreRequestNotification
                                                          object:nil
                                                        userInfo:@{ SRGAnalyticsComScoreLabelsKey : SRGAnalyticsProxyLabelsFromURLComponents(URLComponents) }];
        
    }
    else if ([host containsString:@"wemfbox"]) {
        [NSNotificationCenter.defaultCenter postNotificationName:SRGAnalyticsNetmetrixRequestNotification
                                                          object:nil
                                                        userInfo:@{ SRGAnalyticsNetmetrixURLKey : URL }];
    }
    return [self swizzled_dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

@implementation NSURLConnection (SRGAnalyticsProxy)

+ (void)srg_enableAnalyticsInterceptor
{
    method_exchangeImplementations(class_getClassMethod(self, @selector(sendSynchronousRequest:returningResponse:error:)),
                                   class_getClassMethod(self, @selector(swizzled_sendSynchronousRequest:returningResponse:error:)));
}

+ (NSData *)swizzled_sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse *__autoreleasing  _Nullable *)response error:(NSError * _Nullable __autoreleasing *)error
{
    NSURL *URL = request.URL;
    if ([URL.host containsString:@"tagcommander"]) {
        // The POST body contains URL encoded parameters. Use NSURLComponents for simple extraction
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        URLComponents.query = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        [NSNotificationCenter.defaultCenter postNotificationName:SRGAnalyticsRequestNotification
                                                          object:nil
                                                        userInfo:@{ SRGAnalyticsLabelsKey : SRGAnalyticsProxyLabelsFromURLComponents(URLComponents) }];
    }
    return [self swizzled_sendSynchronousRequest:request returningResponse:response error:error];
}

@end

void SRGAnalyticsEnableRequestInterceptor(void)
{
    if (s_interceptorEnabled) {
        return;
    }
    
    [NSURLSession srg_enableAnalyticsInterceptor];
    [NSURLConnection srg_enableAnalyticsInterceptor];
    
    s_interceptorEnabled = YES;
}
