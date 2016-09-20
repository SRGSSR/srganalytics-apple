//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNetMetrixTracker.h"

#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNotifications.h"
#import "SRGAnalyticsTracker.h"

#import <UIKit/UIKit.h>

static NSString * const LoggerDomainAnalyticsNetMetrix = @"NetMetrix";

@interface SRGAnalyticsNetMetrixTracker ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *businessUnitIdentifier;

@end

@implementation SRGAnalyticsNetMetrixTracker

#pragma mark Object lifecycle

- (instancetype)initWithIdentifier:(NSString *)identifier businessUnitIdentifier:(NSString *)businessUnitIdentifier
{
    if (self = [super init]) {
        self.identifier = identifier;
        self.businessUnitIdentifier = businessUnitIdentifier;
        SRGAnalyticsLogDebug(@"%@ initialization\nAppID: %@\nDomain: %@", LoggerDomainAnalyticsNetMetrix, identifier, self.netMetrixDomain);
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)netMetrixDomain
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSString *> *s_domains;
    dispatch_once(&s_onceToken, ^{
        s_domains = @{ SRGAnalyticsBusinessUnitIdentifierRSI : @"SRGi",
                       SRGAnalyticsBusinessUnitIdentifierRTR : @"rtr",
                       SRGAnalyticsBusinessUnitIdentifierRTS : @"SRG",
                       SRGAnalyticsBusinessUnitIdentifierSRF : @"srf",
                       SRGAnalyticsBusinessUnitIdentifierSWI : @"swissinf" };
    });
    return s_domains[self.businessUnitIdentifier] ?: self.businessUnitIdentifier;
}

#pragma mark View tracking

- (void)trackView
{
    
    NSString *netMetrixURLString = [NSString stringWithFormat:@"http://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", self.netMetrixDomain, self.identifier, self.device];
    NSURL *netMetrixURL = [NSURL URLWithString:netMetrixURLString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:netMetrixURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"image/gif" forHTTPHeaderField:@"Accept"];
    
    // Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
    NSString *systemVersion = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; CPU %@ %@ like Mac OS X)", self.device, self.operatingSystem, systemVersion];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    BOOL testMode = [self.identifier isEqualToString:@"test"] || NSClassFromString(@"XCTestCase") != Nil;
    if (! testMode) {
        SRGAnalyticsLogVerbose(@"%@ : will send view event:\nurl        = %@\nuser-agent = %@", LoggerDomainAnalyticsNetMetrix, netMetrixURLString, userAgent);
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            BOOL success = ! connectionError;
            if (success) {
                SRGAnalyticsLogInfo(@"%@ view > %@", LoggerDomainAnalyticsNetMetrix, request.HTTPMethod);
            }
            else {
                SRGAnalyticsLogError(@"%@ ERROR sending %@ view : %@", LoggerDomainAnalyticsNetMetrix, request.HTTPMethod, connectionError.localizedDescription);
            }
            
            SRGAnalyticsLogDebug(@"%@ view event sent:\n%@", LoggerDomainAnalyticsNetMetrix, [(NSHTTPURLResponse *)response allHeaderFields]);
            
            NSMutableDictionary *userInfo = [@{ SRGAnalyticsNetmetrixRequestSuccessUserInfoKey: @(success) } mutableCopy];
            if (response) {
                userInfo[SRGAnalyticsNetmetrixRequestResponseUserInfoKey] = response;
            }
            if (connectionError) {
                userInfo[SRGAnalyticsNetmetrixRequestErrorUserInfoKey] = connectionError;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsNetmetrixRequestNotification object:request userInfo:[userInfo copy]];
        }];
    }
    else {
        SRGAnalyticsLogWarning(@"%@ response will be fake due to testing flag or xctest bundle presence", LoggerDomainAnalyticsNetMetrix);
    }
}

#pragma mark Information

- (NSString *)device
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"phone";
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return @"tablet";
    }
    else {
        return @"universal";
    }
}

- (NSString *)operatingSystem
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"iPhone OS";
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return @"iPad OS";
    }
    else {
        return @"OS";
    }
}

@end
