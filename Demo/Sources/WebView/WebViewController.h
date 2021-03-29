//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController <WKNavigationDelegate, UIScrollViewDelegate>

- (instancetype)initWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
