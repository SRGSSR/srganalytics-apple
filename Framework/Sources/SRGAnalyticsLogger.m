//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLogger.h"

#pragma clang diagnostic ignored "-Wformat-nonliteral"

@implementation SRGAnalyticsLogger

+ (void) log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ...
{
	char *logLevelString = getenv("SRGAnalyticsLogLevel");
	NSUInteger logLevel = logLevelString ? strtoul(logLevelString, NULL, 0) : DDLogFlagError | DDLogFlagWarning;
	if (!(flag & logLevel))
		return;
	
	va_list arguments;
	va_start(arguments, format);
	NSLog(@"[SRGAnalytics] %@", [[NSString alloc] initWithFormat:format arguments:arguments]);
	va_end(arguments);
}

@end

Class SRGAnalyticsLogClass(void)
{
	static Class logClass;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		logClass = NSClassFromString(@"DDLog");
		if (![logClass methodSignatureForSelector:@selector(log:level:flag:context:file:function:line:tag:format:)])
			logClass = [SRGAnalyticsLogger class];
	});
	return logClass;
}
