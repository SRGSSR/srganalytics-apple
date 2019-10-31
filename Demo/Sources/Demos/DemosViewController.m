//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "AppDelegate.h"
#import "SimpleViewController.h"

#import <SRGAnalytics_Identity/SRGAnalytics_Identity.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

static NSString * const LastLoggedInEmailAddress = @"LastLoggedInEmailAddress";

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Demos", nil);
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidLogin:)
                                                 name:SRGIdentityServiceUserDidLoginNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAccount:)
                                                 name:SRGIdentityServiceDidUpdateAccountNotification
                                               object:nil];
    
    [self reloadData];
}

#pragma mark Data

#pragma mark UITableViewDataSource protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"BasicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @[ @6,
                    @3,
                    @1 ];
    });
    return s_rows[section].integerValue;
}

#pragma mark UITableViewDelegate protocol

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ NSLocalizedString(@"View events", nil),
                      NSLocalizedString(@"Streaming measurements", nil),
                      NSLocalizedString(@"Push notifications", nil) ];
    });
    return s_titles[section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSArray<NSString *> *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ @[ NSLocalizedString(@"Automatic tracking", nil),
                         NSLocalizedString(@"Automatic tracking with levels", nil),
                         NSLocalizedString(@"Automatic tracking with many levels", nil),
                         NSLocalizedString(@"Automatic tracking with levels and labels", nil),
                         NSLocalizedString(@"Manual tracking", nil),
                         NSLocalizedString(@"Missing title", nil) ],
                      @[ NSLocalizedString(@"Live", nil),
                         NSLocalizedString(@"VOD", nil),
                         NSLocalizedString(@"DVR", nil) ],
                      @[ NSLocalizedString(@"From push notification (simulated)", nil) ] ];
    });
    cell.textLabel.text = s_titles[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            SimpleViewController *simpleViewController = nil;
            
            switch (indexPath.row) {
                case 0: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking"
                                                                                levels:nil
                                                                            customInfo:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 1: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with levels"
                                                                                levels:@[@"Level1", @"Level2", @"Level3"]
                                                                            customInfo:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 2: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with many levels"
                                                                                levels:@[@"Level1", @"Level2", @"Level3", @"Level4", @"Level5", @"Level6", @"Level7", @"Level8", @"Level9", @"Level10", @"Level11", @"Level12"]
                                                                            customInfo:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 3: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with levels and labels"
                                                                                levels:@[@"Level1", @"Level2"]
                                                                            customInfo:@{ @"custom_label": @"custom_value" }
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 4: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Manual tracking"
                                                                                levels:nil
                                                                            customInfo:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:NO];
                    break;
                }
                    
                case 5: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@""
                                                                                levels:nil
                                                                            customInfo:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                default: {
                    return;
                    break;
                }
            }
            [self.navigationController pushViewController:simpleViewController animated:YES];
            break;
        }
            
        case 1: {
            NSURL *URL = nil;
            
            switch (indexPath.row) {
                case 0: {
                    URL = [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8?dw=0"];
                    break;
                }
                    
                case 1: {
                    URL = [NSURL URLWithString:@"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"];
                    break;
                }
                    
                case 2: {
                    URL = [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"];
                    break;
                }
                    
                default: {
                    return;
                    break;
                }
            }
            
            SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
            labels.customInfo = @{ @"media_id" : @(indexPath.row).stringValue };
            labels.comScoreCustomInfo = @{ @"media_id" : @(indexPath.row).stringValue };
            
            SRGMediaPlayerViewController *playerViewController = [[SRGMediaPlayerViewController alloc] init];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [playerViewController.controller playURL:URL atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 2: {
            UIViewController *simpleViewController = [[SimpleViewController alloc] initWithTitle:@"From push notification"
                                                                                          levels:nil
                                                                                      customInfo:nil
                                                                      openedFromPushNotification:YES
                                                                            trackedAutomatically:YES];
            [self.navigationController pushViewController:simpleViewController animated:YES];
            break;
        }
            
        default: {
            return;
            break;
        }
    }
}

#pragma mark UI

- (void)reloadData
{
    SRGIdentityService *identityService = SRGIdentityService.currentIdentityService;
    
    if (identityService.loggedIn) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(logout:)];
    }
    else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Login", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(login:)];
    }
}

#pragma mark Actions

- (void)login:(id)sender
{
    NSString *lastEmailAddress = [NSUserDefaults.standardUserDefaults stringForKey:LastLoggedInEmailAddress];
    [SRGIdentityService.currentIdentityService loginWithEmailAddress:lastEmailAddress];
}

- (void)logout:(id)sender
{
    [SRGIdentityService.currentIdentityService logout];
}

#pragma mark Notifications

- (void)userDidLogin:(NSNotification *)notification
{
    [self reloadData];
}

- (void)didUpdateAccount:(NSNotification *)notification
{
    [self reloadData];
    
    NSString *emailAddress = SRGIdentityService.currentIdentityService.emailAddress;;
    if (emailAddress) {
        [NSUserDefaults.standardUserDefaults setObject:emailAddress forKey:LastLoggedInEmailAddress];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

@end
