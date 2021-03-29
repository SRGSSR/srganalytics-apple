//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WebTesterViewController.h"

#import "Resources.h"

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
}

- (IBAction)openWithInAppBrowser:(id)sender
{
    [self.URLTextField resignFirstResponder];
}

- (IBAction)openWithDeviceBrowser:(id)sender
{
    [self.URLTextField resignFirstResponder];
}

@end
