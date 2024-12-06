//
//  RGHomeViewController.m
//  RedteaGo
//
//  Created by UnknownFFF on 2019/10/20.
//  Copyright © 2019 Redtea. All rights reserved.
//  首页

#import "RGHomeViewController.h"
#import <TTGTagCollectionView/TTGTextTagCollectionView.h>
#import "JLLocationPermission.h"
#import "JLNotificationPermission.h"
#import "RGAPPSettingManager.h"
#import "RGPromoCodeApiManager.h"
#import "RGPromoModel.h"
#import "RGAppUpdater.h"
#import "RGUIUtil.h"
#import "RGUnSupportESIMAlert.h"
#import "RGEsimStatusAlert.h"
@import Firebase;

static NSString *HOME_URL_JP = @"https://esim.jetfimobile.com/home-jp";
static NSString *HOME_URL_JP_QA = @"https://esimtest.jetfimobile.com/home-jp";
@interface RGHomeViewController () <TTGTextTagCollectionViewDelegate,JLLocationManagerDelegate>

/// 远程配置
@property (nonatomic, strong) FIRRemoteConfig *remoteConfig;

@property (nonatomic, strong) NSArray *urlOpenInOtherArr;
@property (nonatomic, strong) NSURL *pathURL;

@end

@implementation RGHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kDontTipUnSupportESim]) {
        [self setPermissionsSetting];
    } else if ([current_version() compare:prev_version()] != NSOrderedDescending) {//NSOrderedSame NSOrderedDescending
        [self checkESIMStatus];
    }
    
    [self setupRemoteConfig];
    
    if ([RGPublicSettingConfig.currentSetting checkLanguage]) {
        [NotificationCenter postNotificationName:kloadShareDataNotification object:nil];
    }
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    if (@available(iOS 13.0, *)) {
//        return UIStatusBarStyleLightContent;
//    } else {
//        // Fallback on earlier versions
//        return UIStatusBarStyleDefault;
//    }
//}

- (void)setPermissionsSetting {
    [self showLocationSetting];
    [self showNotificationPermissionsView];
}
- (void)loationMangerSuccessLocationWithCountryCode:(NSString *)countryCode {
    kAPPCountryCode = countryCode;
    [[RGAPPSettingManager sharedManager] saveData];
}

- (void)showLocationSetting {
    JLAuthorizationStatus authorizationStatus = [[JLLocationPermission sharedInstance] authorizationStatus];
    BOOL locationPermissionStatus = (authorizationStatus == JLPermissionNotDetermined);//未授权或者允许授权后
    BOOL locationCuntinuePermissionStatus = (authorizationStatus == JLPermissionAuthorized);//允许授权过
    
//    NSLog(@"%d",locationPermissionStatus);//等于0只有是允许预授权确拒绝授权
    [[JLLocationPermission sharedInstance] setExtraAlertEnabled:locationPermissionStatus == YES ? YES:NO];
    if (locationCuntinuePermissionStatus) {
        [[JLLocationPermission sharedInstance] startLocate];//请求定位
    }

    [JLLocationPermission sharedInstance].delegate = self;
    [[JLLocationPermission sharedInstance] authorize:^(bool granted, NSError *error) {
//        NSLog(@"locations returned %@ with error %@", @(granted), error);
    }];
}
- (void)showNotificationPermissionsView {
    BOOL notificationPermissionStatus = [[JLNotificationPermission sharedInstance] authorizationStatus] == JLPermissionNotDetermined;//未授权
    [[JLNotificationPermission sharedInstance] setExtraAlertEnabled:notificationPermissionStatus == YES ? YES:NO];
    [[JLNotificationPermission sharedInstance] authorize:^(NSString *deviceID, NSError *error) {
//      NSLog(@"pushNotifications returned %@ with error %@", deviceID, error);
    }];
}
- (void)addObservers {
    [NotificationCenter addObserver:self selector:@selector(onShowGuaidViewFinished) name:kShowGuaidViewFinishedNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(onReloadUrl:) name:kReloadUrlNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(onLoadCustomUrl:) name:kLoadCustomURLNotification2 object:nil];
}

- (void)onLoadCustomUrl:(NSNotification *)notification {
    NSString *customURLString = notification.object;
    NSLog(@"Received custom URL: %@", customURLString);
    if (customURLString.length > 0) {
        NSURL *customURL = [NSURL URLWithString:customURLString];
        if (customURL) {
            NSLog(@"Loading custom URL: %@", customURLString);
            [RGProgressHUD showHUD];
            NSURLRequest *request = [NSURLRequest requestWithURL:customURL];
            [self.webView stopLoading];
            [self.webView loadRequest:request];
        } else {
            NSLog(@"Invalid custom URL: %@", customURLString);
        }
    } else {
        NSLog(@"Custom URL is empty.");
    }
}

- (void)onShowGuaidViewFinished {
    [self checkESIMStatus];
}

- (void)onReloadUrl:(NSNotification *)notification {
    if ([@"0" isEqualToString: notification.object]) {
        [self loadDatas];
    }
}

- (void)checkESIMStatus {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kSupportESim] && ![@"ja" isEqualToString:APP_LANGUAGE]) {
        [self setPermissionsSetting];
        return;
    }
    
    RGEsimStatusAlert *alert = [[RGEsimStatusAlert alloc] init];
    [alert showEsimStatusAlert:YES];
    
    alert.buttonLearnMornBlock = ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onShowPermissionsNotification:)
            name:kShowPermissionsNotification
          object:nil];
    };
}

#pragma mark - 远程配置
//配置远程配置(google)
- (void)setupRemoteConfig {
    self.remoteConfig = [FIRRemoteConfig remoteConfig];
    FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] init];
    remoteConfigSettings.minimumFetchInterval = 0;
    self.remoteConfig.configSettings = remoteConfigSettings;
    [self.remoteConfig setDefaultsFromPlistFileName:kRGRemoteConfigDefaults];
    [self fetchConfig];
}

- (void)fetchConfig {
    // [START fetch_config_with_callback]
    [self.remoteConfig fetchAndActivateWithCompletionHandler:^(FIRRemoteConfigFetchAndActivateStatus status, NSError * _Nullable error) {
        
        NSString *urlOpenInOtherStr = self.remoteConfig[kRGURLOpenInOtherConfig].stringValue;
        if (urlOpenInOtherStr.length > 0) {
            [[NSUserDefaults standardUserDefaults] setValue:urlOpenInOtherStr forKey:kUrlOpenInOtherStr];
            self.urlOpenInOtherArr = [NSJSONSerialization JSONObjectWithData:[urlOpenInOtherStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:NULL];
        }
        NSString *urlESimMoreStr = self.remoteConfig[kRGUrlESimMoreConfig].stringValue;
        [[NSUserDefaults standardUserDefaults] setValue:urlESimMoreStr forKey:kUrlESimMore];
        if (status == FIRRemoteConfigFetchStatusSuccess) {
            [self.remoteConfig activateWithCompletion:^(BOOL changed, NSError * _Nullable error) {
                
            }];
        } else {//配置获取失败
            NSLog(@"Config not fetched");
            NSLog(@"Error %@", error.localizedDescription);
        }
    }];
}

- (void)onShowPermissionsNotification:(NSNotification *)notificaiton {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShowPermissionsNotification object:nil];
    
    [self setPermissionsSetting];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[RGEventAnalysis sharedInstance] sendEvent:RGEventAnalysisNameEnterHomeVC];
}


#pragma mark - 加载数据
- (void)loadDatas {
    if (self.webView.URL && self.webView.URL.absoluteString.length > 0) {
        NSLog(@"WebView is already loading a URL: %@", self.webView.URL.absoluteString);
        return; // Do not reload the default URL if a custom URL is already loaded
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *homeH5Address = [defaults stringForKey:kHomeH5AddressRemoteConfig];
    
    if ([@"ja" isEqualToString:APP_LANGUAGE]) {
        if ([@"https://esim.redteatest.com" isEqualToString:HostURL]) {
            homeH5Address = HOME_URL_JP_QA;
        } else {
            homeH5Address = HOME_URL_JP;
        }
    }
    
    homeH5Address = [RGPublicSettingConfig.currentSetting getUrlWithLanguage:homeH5Address];
    
    NSLog(@"homeH5Address: %@", homeH5Address);
    self.pathURL = [NSURL URLWithString:homeH5Address];

    NSURLRequest *request = [NSURLRequest requestWithURL:self.pathURL];
    [self.webView loadRequest:request];
}


NS_INLINE
NSString* current_version(){
    return [NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

NS_INLINE
NSString* prev_version(){
    return [NSString stringWithContentsOfFile:version_path() encoding:NSUTF8StringEncoding error:nil];
}

NS_INLINE
NSString* version_path(){
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Version.data"];;
}

@end
