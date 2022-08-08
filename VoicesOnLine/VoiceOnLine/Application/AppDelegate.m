//
//  AppDelegate.m
//  VoiceOnLine
//

#import "AppDelegate.h"
#import "QMUIConfigurationTemplate.h"
#import "AppDelegate+Config.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self configurationQMUITemplate];
    [self configRootViewController];
    [self configureKeyboard];
    return YES;
}

- (void)configurationQMUITemplate {
    QMUIThemeManagerCenter.defaultThemeManager.themeGenerator = ^__kindof NSObject * _Nonnull(NSString * _Nonnull identifier) {
        if ([identifier isEqualToString:QDThemeIdentifierDefault]) return QMUIConfigurationTemplate.new;
        return nil;
    };

    QMUIThemeManagerCenter.defaultThemeManager.currentThemeIdentifier = QDThemeIdentifierDefault;
    [QDThemeManager.currentTheme applyConfigurationTemplate];
    [QDCommonUI renderGlobalAppearances];

    if (@available(iOS 13.0, *)) {
        
        QMUIThemeManagerCenter.defaultThemeManager.identifierForTrait = ^__kindof NSObject<NSCopying> * _Nonnull(UITraitCollection * _Nonnull trait) {
            
            return QMUIThemeManagerCenter.defaultThemeManager.currentThemeIdentifier;
        };
        QMUIThemeManagerCenter.defaultThemeManager.respondsSystemStyleAutomatically = false;
    }

}

- (void)configureKeyboard {
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    manager.enable = YES;
    manager.shouldResignOnTouchOutside =YES;
    manager.enableAutoToolbar = NO;
}

@end
