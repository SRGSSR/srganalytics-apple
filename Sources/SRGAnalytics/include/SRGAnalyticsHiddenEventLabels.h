//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Additional hidden event labels. Data associated with a hidden event is generic (type, values and source) and
 *  therefore flexible. Your measurement team should provide you precise guidelines about which information must
 *  be sent in hidden events, and in which fields.
 */
@interface SRGAnalyticsHiddenEventLabels : SRGAnalyticsLabels

/**
 *  The event type.
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 *  The main value associated with the event.
 */
@property (nonatomic, copy, nullable) NSString *value;

/**
 *  Additional values associated with the event.
 */
@property (nonatomic, copy, nullable) NSString *extraValue1;
@property (nonatomic, copy, nullable) NSString *extraValue2;
@property (nonatomic, copy, nullable) NSString *extraValue3;
@property (nonatomic, copy, nullable) NSString *extraValue4;
@property (nonatomic, copy, nullable) NSString *extraValue5;

/**
 *  The event source.
 */
@property (nonatomic, copy, nullable) NSString *source;

@end

NS_ASSUME_NONNULL_END
