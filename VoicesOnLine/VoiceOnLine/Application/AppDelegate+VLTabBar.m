//
//  AppDelegate+VLTabBar.m
//  VoiceOnLine
//

#import "AppDelegate+VLTabBar.h"
#import "VLMainRootViewController.h"


@implementation AppDelegate (VLTabBar) 

#pragma mark - Public Methods
- (void)vj_configureTabBarController {
    VLMainRootViewController *rootViewController = [[VLMainRootViewController alloc] init];
    [self.window setRootViewController:rootViewController];
}

@end
