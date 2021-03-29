//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WebTesterViewController.h"

#import "Resources.h"

@import SafariServices;

@interface WebTesterViewController ()

@property (nonatomic, weak) IBOutlet UITextField *URLTextField;

@end

@implementation WebTesterViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    return storyboard.instantiateInitialViewController;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Web tester", nil);
}

#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.URLTextField becomeFirstResponder];
}

#pragma mark Helpers

- (NSURL *)checkURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    if (URL) {
        return URL;
    }
    else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid URL", nil)
                                                                                 message:NSLocalizedString(@"The text entered is not a valid URL", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        return nil;
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return @"web-tester";
}

#pragma mark UITextFieldDelegate protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark Actions

- (IBAction)openWithInAppWebView:(id)sender
{
    [self.URLTextField resignFirstResponder];
    
    NSURL *URL = [self checkURLString:self.URLTextField.text];
    if (URL) {
        
    }
}

- (IBAction)openWithInAppBrowser:(id)sender
{
    [self.URLTextField resignFirstResponder];
    
    NSURL *URL = [self checkURLString:self.URLTextField.text];
    if (URL) {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
        [self presentViewController:safariViewController animated:YES completion:nil];
    }
}

- (IBAction)openWithDeviceBrowser:(id)sender
{
    [self.URLTextField resignFirstResponder];
    
    NSURL *URL = [self checkURLString:self.URLTextField.text];
    if (URL) {
        if (@available(iOS 10, *)) {
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
        }
        else {
            [UIApplication.sharedApplication openURL:URL];
        }
    }
}

@end
