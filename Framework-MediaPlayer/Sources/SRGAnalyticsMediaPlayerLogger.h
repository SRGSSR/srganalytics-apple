//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLogger/SRGLogger.h>

/**
 *  Helper macros for logging.
 */
#define SRGAnalyticsMediaPlayerLogVerbose(category, format, ...) SRGLogVerbose(@"ch.srgssr.analytics.mediaplayer", category, format, ##__VA_ARGS__)
#define SRGAnalyticsMediaPlayerLogDebug(category, format, ...)   SRGLogDebug(@"ch.srgssr.analytics.mediaplayer", category, format, ##__VA_ARGS__)
#define SRGAnalyticsMediaPlayerLogInfo(category, format, ...)    SRGLogInfo(@"ch.srgssr.analytics.mediaplayer", category, format, ##__VA_ARGS__)
#define SRGAnalyticsMediaPlayerLogWarning(category, format, ...) SRGLogWarning(@"ch.srgssr.analytics.mediaplayer", category, format, ##__VA_ARGS__)
#define SRGAnalyticsMediaPlayerLogError(category, format, ...)   SRGLogError(@"ch.srgssr.analytics.mediaplayer", category, format, ##__VA_ARGS__)
