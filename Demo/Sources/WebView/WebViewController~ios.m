//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WebViewController.h"

#import "Resources.h"

@import libextobjc;

static void *s_kvoContext = &s_kvoContext;

@interface WebViewController ()

@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSURL *currentURL;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end

@implementation WebViewController

#pragma mark Object lifecycle

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    if (self = [self initFromStoryboard]) {
        self.request = request;
    }
    return self;
}

- (instancetype)initFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    return storyboard.instantiateInitialViewController;
}

- (void)dealloc
{
    self.webView = nil;             // Unregister KVO
}

#pragma mark Getters and setters

- (void)setWebView:(WKWebView *)webView
{
    [_webView removeObserver:self forKeyPath:@keypath(WKWebView.new, estimatedProgress) context:s_kvoContext];
    _webView = webView;
    [_webView addObserver:self forKeyPath:@keypath(WKWebView.new, estimatedProgress) options:NSKeyValueObservingOptionNew context:s_kvoContext];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // WKWebView cannot be instantiated in storyboards, do it programmatically
    WKWebView *webView = [[WKWebView alloc] init];
    webView.navigationDelegate = self;
    webView.scrollView.delegate = self;
    [self.view insertSubview:webView atIndex:0];
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [webView.bottomAnchor constraintEqualToAnchor:self.toolbar.topAnchor]
    ]];
    
    if (@available(iOS 11, *)) {
        [NSLayoutConstraint activateConstraints:@[
            [webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [webView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
            [webView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor]
        ]];
    }
    else {
        [NSLayoutConstraint activateConstraints:@[
            [webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
    }
    
    self.webView = webView;
    
    self.errorLabel.text = nil;
    
    self.progressView.progressTintColor = UIColor.systemBlueColor;
    
    [self.webView loadRequest:self.request];
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    self.errorLabel.text = nil;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.progressView.alpha = 1.f;
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    self.errorLabel.text = nil;
    
    self.currentURL = self.webView.URL;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.f;
        self.progressView.alpha = 0.f;
    }];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        self.errorLabel.text = error.localizedDescription;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.f;
            self.webView.alpha = 0.f;
        }];
    }
    else {
        self.errorLabel.text = nil;
        
        [webView goBack];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.f;
        }];
    }
}

#pragma mark Actions

- (IBAction)goBack:(id)sender
{
    [self.webView goBack];
}

- (IBAction)goForward:(id)sender
{
    [self.webView goForward];
}

- (IBAction)refresh:(id)sender
{
    if (self.currentURL.absoluteString.length != 0) {
        [self.webView reload];
    }
    else {
        [self.webView loadRequest:self.request];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        if ([keyPath isEqualToString:@keypath(WKWebView.new, estimatedProgress)]) {
            self.progressView.progress = self.webView.estimatedProgress;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
