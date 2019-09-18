//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLogger/SRGLogger.h>

/**
 *  Helper macros for logging.
 */
#define SRGAnalyticsDataProviderLogVerbose(category, format, ...) SRGLogVerbose(@"ch.srgssr.analytics.dataprovider", category, format, ##__VA_ARGS__)
#define SRGAnalyticsDataProviderLogDebug(category, format, ...)   SRGLogDebug(@"ch.srgssr.analytics.dataprovider", category, format, ##__VA_ARGS__)
#define SRGAnalyticsDataProviderLogInfo(category, format, ...)    SRGLogInfo(@"ch.srgssr.analytics.dataprovider", category, format, ##__VA_ARGS__)
#define SRGAnalyticsDataProviderLogWarning(category, format, ...) SRGLogWarning(@"ch.srgssr.analytics.dataprovider", category, format, ##__VA_ARGS__)
#define SRGAnalyticsDataProviderLogError(category, format, ...)   SRGLogError(@"ch.srgssr.analytics.dataprovider", category, format, ##__VA_ARGS__)
