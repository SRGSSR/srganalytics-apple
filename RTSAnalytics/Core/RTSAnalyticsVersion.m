//
//  RTSAnalyticsVersion.m
//  RTSAnalytics
//
//  Created by Samuel Defago on 18.06.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#define RTSStringize_(x) #x
#define RTSStringize(x) RTSStringize_(x)

#import "RTSAnalyticsVersion_private.h"

NSString * const RTSAnalyticsVersion(void)
{
#ifdef RTS_ANALYTICS_VERSION
    return @(RTSStringize(RTS_ANALYTICS_VERSION));
#else
    #warning No explicit version has been specified, set to "dev". Compile the project with a preprocessor macro called RTS_ANALYTICS_VERSION supplying the version number (without quotes)
    return @"dev";
#endif
}
