//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The media player tracker class internally listens to SRG MediaPlayer controller notifications to provide automatic
 *  tracking of media consumption. A tracker is automatically associated with a player controller when it prepares
 *  to play, and is removed when the player returns to the idle state.
 */
@interface SRGMediaPlayerTracker : NSObject

@end

@interface SRGMediaPlayerTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
