//
//  AppDelegate+Config.m
//  VoiceOnLine
//

#import "AppDelegate+Config.h"
#import "AppDelegate+VLTabBar.h"
#import "VLLoginViewController.h"

@implementation AppDelegate (Config)

- (void)configRootViewController {
    if ([VLUserCenter center].isLogin) {
        [self vj_configureTabBarController];
    } else {
        VLLoginViewController *lvc = [[VLLoginViewController alloc] init];
        BaseNavigationController *navi = [[BaseNavigationController alloc] initWithRootViewController:lvc];
        self.window.rootViewController = navi;
    }
}

@end
