//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGLogger;

/**
 *  Helper macros for logging.
 */
#define SRGAnalyticsLogVerbose(category, format, ...) SRGLogVerbose(@"ch.srgssr.analytics", category, format, ##__VA_ARGS__)
#define SRGAnalyticsLogDebug(category, format, ...)   SRGLogDebug(@"ch.srgssr.analytics", category, format, ##__VA_ARGS__)
#define SRGAnalyticsLogInfo(category, format, ...)    SRGLogInfo(@"ch.srgssr.analytics", category, format, ##__VA_ARGS__)
#define SRGAnalyticsLogWarning(category, format, ...) SRGLogWarning(@"ch.srgssr.analytics", category, format, ##__VA_ARGS__)
#define SRGAnalyticsLogError(category, format, ...)   SRGLogError(@"ch.srgssr.analytics", category, format, ##__VA_ARGS__)
