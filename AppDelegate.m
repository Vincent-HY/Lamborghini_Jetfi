//
//  AppDelegate.m
//  RedteaGo
//
//  Created by UnknownFFF on 2019/10/18.
//  Copyright © 2019 Redtea. All rights reserved.
//

#import "AppDelegate.h"
#import "UIApplication+Init.h"
#import <AppsFlyerLib/AppsFlyerLib.h>
#import "RGLoginManager.h"
#import "RGUserApiManager.h"
#import "RGAccountApiManager.h"
#import "UserDefaultsUtils.h"
#import "RGEventAnalysis.h"
#import <UserNotifications/UserNotifications.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "RGPopPromoCodeViewController.h"
#import "JLNotificationPermission.h"
#import "RGPayTypeModel.h"
@import GoogleSignIn;
@import Firebase;
#import "RGMainTabController.h"
#import "RGHomeViewController.h"
#import <Stripe/Stripe.h>
#import <AppsFlyerLib/AppsFlyerLib.h>


@interface AppDelegate ()<UNUserNotificationCenterDelegate,UIApplicationDelegate,FIRMessagingDelegate,AppsFlyerLibDelegate>

@end

@implementation AppDelegate

/*
 - (void)sendLaunch:(UIApplication *)application {
     [[AppsFlyerLib shared] start];
 }
 */

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
     
     //[AppsFlyerLib shared].delegate = self;  // Set delegate
     //[AppsFlyerLib shared].isDebug = YES;    // Optional: Enable debug mode for development
     //[AppsFlyerLib shared].minTimeBetweenSessions = 30;
     
    [self registerThirdLoginWithApplication:application andLaunchOptions:launchOptions];
    [self addObservers];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [application initialize];
//    [application changeAppLanguage];
    [self readFileToClip];
    if (![RGLoginManager isClipEnter]) {//clip登录不需要guide引导页面
        [application launchGuideViewWithScene];
    }
    
    [self.window makeKeyAndVisible];
    [application setupMainViewController];
    
    //通过 openURL: 启动
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        //对应启动的源应用程序的 bundle ID (NSString)
        id source = [launchOptions objectForKey:UIApplicationLaunchOptionsSourceApplicationKey];
        [self application:application openURL:url options:@{UIApplicationOpenURLOptionsSourceApplicationKey : (source ? source : @"")}];
    }
    
    //[AppsFlyerLib shared].isDebug = true;
    //[AppsFlyerLib shared].setAppsFlyerDevKey = @"cftfhgEJscDKJU76z5bsf5";
    [[AppsFlyerLib shared] setAppsFlyerDevKey:@"cftfhgEJscDKJU76z5bsf5"];
    [[AppsFlyerLib shared] setAppsFlyerDevKey:@"8Fwo6ZCfLU34HbXqMaLFFY"];
    [[AppsFlyerLib shared] setAppleAppID:@"id1492864476"];
    
    //[FIRApp configure];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *jetfiLoginToken = [defaults stringForKey:kJetfiLoginToken];
    if (jetfiLoginToken.length == 0 && kUserToken.length > 0) {
        [self clearLoginInfo];
    }
    return YES;
}

- (void)clearLoginInfo {
    [[RGLoginManager sharedManager] clearData];
    //移除本地通知
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [center removeAllPendingNotificationRequests];
    
    FBSDKLoginManager *fbLogin = [[FBSDKLoginManager alloc] init];
    [fbLogin logOut];
    [FBSDKAccessToken setCurrentAccessToken:nil];
    
    GIDSignIn *googleLogin = [GIDSignIn sharedInstance];
    [googleLogin signOut];
}

#pragma mark --clip购买订单首次打开app入口
- (void)readFileToClip {
    /*
     登录完后会清空数据,导致token失效!!!
    */
    [[RGLoginManager sharedManager] loadDataToGroup];
    if ([RGLoginManager isClipEnter]) {//clip如果登录就直接进入订单页面
        [[Utility topViewController].tabBarController setSelectedIndex:1];
        [WBGRouter openURL:kDeepLinkUrlESimViewController];
        [NotificationCenter postNotificationName:kLoginSuccessNotification object:nil];
        [NotificationCenter postNotificationName:kloadShareDataNotification object:nil];
    }
    [[RGLoginManager sharedManager] deleteDataToGroup];
}
/*
 - (void)sendAppleiAds {
     // Check for iOS 10 attribution implementation
     if ([[ADClient sharedClient] respondsToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
         [[ADClient sharedClient] requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
             
         // Look inside of the returned dictionary for all attribution details
             NSLog(@"Attribution Dictionary: %@", attributionDetails);
             [[RGUserApiManager new] upload_ads_data:attributionDetails :^(RGBaseApiResponse * _Nullable response) {
             }];
         }];
     }
 }
 */
#pragma mark - 第三方登录配置
- (void)registerThirdLoginWithApplication:(UIApplication *)application andLaunchOptions:(NSDictionary *)launchOptions {
    if ([@"https://esim.redteago.com" isEqualToString:HostURL]) {
        //正式
        [Stripe setDefaultPublishableKey:@"pk_live_51HFHYuIuTptIExW8Vy5fJ6mkHkllKd8o5EAsHVuf6BQzqiiy1GqDxrynCtjk0qZMQD8yILcpjSWxvoAqTxxrYxSE00RGLIra6K"];
    } else {
        //测试
        [Stripe setDefaultPublishableKey:@"pk_test_51HFHYuIuTptIExW8Zf0ZcDAiLMkJIaOopv2PYqPMPDVvBrjVE6t2LV1kgmXY7SOZDI5a23z5NGKqSwvQ7NWDtClj00BVhUHaH3"];
    }
    
    //MARK:FD第三方登录配置
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    //Google第三方登录配置
    [GIDSignIn sharedInstance].clientID = APP_Google_clientID;
    
    //FIRApp配置
    [FIRApp configure];
    // [START set_messaging_delegate]
    [FIRMessaging messaging].delegate = self;
    [[FIRCrashlytics crashlytics] setUserID:kUserEmail];
}
/**
 应用进入前台时调用
 @param application 应用
 */
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];//进入前台取消应用消息图标（被取代了）
}
#pragma mark -application 活跃状态
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents.shared activateApp];//变成活跃状态
    [[AppsFlyerLib shared] startWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable dictionary, NSError * _Nullable error) {
        if (error) {
            NSLog(@"AppsFlyerLib start error: %@", error);
            return;
        }
        if (dictionary) {
            NSLog(@"AppsFlyerLib start dictionary: %@", dictionary);
            return;
        }
    }];
}
#pragma mark - 进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}
#pragma mark - 本地通知 && APNS通知
- (void)registerLocalAndRemoteNotification:(UIApplication *)application {
     // 注册通知
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
//    UNAuthorizationOptionBadge 角标暂时不需要
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];
    [application registerForRemoteNotifications];
}
#pragma mark - 通知
/// 点击进入通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID: %@ %@", userInfo[kGCMMessageIDKey],userInfo);
        NSString *link = userInfo[@"deeplink"];
        [self messageDeeplinkAction:link];
    }
    
    if(![response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        // 判断为本地通知(时间到期)
        [[Utility topViewController].navigationController popToRootViewControllerAnimated:NO];
        [[Utility topViewController].tabBarController setSelectedIndex:1];
        [WBGRouter openURL:kDeepLinkUrlESimViewController];
    }
    completionHandler();
}

//收到通知(目前解决办法是,在活跃状态不处理跳转逻辑,在非活跃状态下才处理跳转逻辑,正好可以解决,通知在后台点击只会走这个代理所产生的问题)
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
        [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
        if (application.applicationState == UIApplicationStateBackground || application.applicationState == UIApplicationStateInactive) {
            NSLog(@"非活跃才跳转");
            NSString *link = userInfo[@"deeplink"];
            // 在前台收到推送内容, 执行的方法
            [self messageDeeplinkAction:link];
        }
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

//本地通知()
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandle {
    
    if(![notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        // 判断为本地通知(时间到期)
        [[Utility topViewController].navigationController popToRootViewControllerAnimated:NO];
        [[Utility topViewController].tabBarController setSelectedIndex:1];
        [WBGRouter openURL:kDeepLinkUrlESimViewController];
    } else {
        //远程通知
        NSDictionary *userInfo = notification.request.content.userInfo;
        [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
        if (userInfo[kGCMMessageIDKey]) {
          NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
            NSString *link = userInfo[@"deeplink"];
            // 在前台收到推送内容, 执行的方法(前台不需要跳转deeplink)
//            [self messageDeeplinkAction:link];
        }
    }
    completionHandle(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
}

/// 此处拿到的每次最新的FCM的devicetoken
/// @param messaging messaging
/// @param fcmToken fcmToken
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
//    NSLog(@"FCM registration token: %@", fcmToken);
    // Notify about received token.
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:fcmToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     @"FCMToken" object:nil userInfo:dataDict];
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:fcmToken forKey:kChannelDeviceToken];
    [defaults synchronize];
    [self sendDeviceInfo];
}
#pragma mark -NotificationPermission权限
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Unable to register for remote notifications: %@", error);
    [[JLNotificationPermission sharedInstance] notificationResult:nil error:error];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[JLNotificationPermission sharedInstance] notificationResult:deviceToken error:nil];
    [[AppsFlyerLib shared] registerUninstall:deviceToken];
}
//iOS6被废弃
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//}

#pragma mark Deeplink跳转(FCM)
- (void)messageDeeplinkAction:(NSString *)link {
    if ([link hasPrefix:@"wifiesim"]) {//跳转具体国家
        NSArray *arr = [link componentsSeparatedByString:@"?"];
        NSString *url = arr.firstObject;
        NSDictionary *queryParams = [[arr.lastObject stringByRemovingPercentEncoding] DPL_parametersFromQueryString];
        [WBGRouter openURL:url withParam:queryParams];
    } else if([NSString isValidURL:link]) {
        [WBGRouter openURL:kDeepLinkUrlWebViewController withParam:@{@"url" : [NSURL URLWithString:link]}];
    }
}

#pragma mark - 注册事件
- (void)signupAction:(id)object{
    NSDictionary *loginDic = object;
    RGRedteaGOLoginStatus loginType = (RGRedteaGOLoginStatus)[[loginDic valueForKey:@"type"] integerValue];
    
    if (loginType == RGRedteaGOLoginStatusSignup) {//表示新注册用户
        //[self sendAppleiAds];
        NSInteger balance = kUserBalance;
        if (balance == 0) {
            // jetfi 去除兑换码的弹框
//            [self showInvateCodeView];
        }
    }
}
- (void)showInvateCodeView {
    RGPopPromoCodeViewController *popVc = [[RGPopPromoCodeViewController alloc] init];
    [popVc popup];
}
#pragma mark - 上传设备信息
- (void)sendDeviceInfo {
    [[RGUserApiManager new] uploadDeviceInfoWithCompletionHandler:^(RGBaseApiResponse * _Nullable response) {
    }];
    [[RGUserApiManager new] uploadNoticationInfoWithCompletionHandler:^(RGBaseApiResponse * _Nullable response) {
        if (!response.success) {
            [RGProgressHUD showAlert:response.msg];
            return;
        }
    }];
}
#pragma mark - NotificationCenter通知
- (void)addObservers {
    [NotificationCenter addObserver:self selector:@selector(loadUserInfoNotification:) name:kloadUserInfoNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(loginSuccessNotification:) name:kLoginSuccessNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(logoutSuccessNotification:) name:kLogoutSuccessNotification object:nil];
}

#pragma mark - Notifications
/// 更新用户数据
- (void)loadUserInfoNotification:(NSNotification *)notification {
    [[RGAccountApiManager new] requestUserInfoWithCompletionHandler:^(RGBaseApiResponse * _Nullable response) {
        if (!response.success) {
            [RGProgressHUD showAlert:response.msg];
            return;
        }
    }];
}
- (void)logoutSuccessNotification:(NSNotification *)notification {
    NSDictionary *notificationDic = notification.object;
    
    [[RGLoginManager sharedManager] clearData];
    //移除本地通知
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [center removeAllPendingNotificationRequests];
    
    FBSDKLoginManager *fbLogin = [[FBSDKLoginManager alloc] init];
    [fbLogin logOut];
    [FBSDKAccessToken setCurrentAccessToken:nil];
    
    GIDSignIn *googleLogin = [GIDSignIn sharedInstance];
    [googleLogin signOut];
    
    if ([[notificationDic valueForKey:@"source"] isEqualToString:kDeepLinkUrlLoginWebViewController]) {
        [[UIApplication sharedApplication] enterLoginVc];
    } else {
        //默认进入首页
        [NotificationCenter postNotificationName:kloadHomeDataNotification object:nil];
        [[UIApplication sharedApplication] setupMainViewController];//进入首页
    }
}
- (void)loginSuccessNotification:(NSNotification *)notification {
    [self signupAction:notification.object];
    [self sendDeviceInfo];
    [NotificationCenter postNotificationName:kloadHomeDataNotification object:nil];
    [NotificationCenter postNotificationName:kloadUserInfoNotification object:nil];
    
}

//#pragma mark - UISceneSession lifecycle
//
//- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
//    // Called when a new scene session is being created.
//    // Use this method to select a configuration to create the new scene with.
//    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
//}
//
//
//- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
//    // Called when the user discards a scene session.
//    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//}
/**
 iOS 9.0 之后    程序在运行过程中才能调用
 三方唤起本程序后执行的方法
 return YES 表示允许唤起本程序
 */
- (BOOL)hasLoginToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:kJetfiLoginToken];
    return (token != nil && token.length > 0);
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    // Handle Facebook deep links
    if ([url.scheme containsString:@"fb"]) {
        return [[FBSDKApplicationDelegate sharedInstance] application:app
                                                              openURL:url
                                                    sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                           annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }

    // Handle Alipay deep links
    if ([url.host isEqualToString:@"safepay"]) {
        // Handle payment result
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            if ([[resultDic objectForKey:@"resultStatus"] isEqualToString:@"9000"]) {
                [NotificationCenter postNotificationName:kPaySuccessNotification object:@{@"payType": GetPayType(RGPayTypeAlipay)}];
            } else {
                [NotificationCenter postNotificationName:kPayFailNotification object:@{@"payType": GetPayType(RGPayTypeAlipay)}];
            }
        }];
        
        // Handle authentication result
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            if ([[resultDic objectForKey:@"resultStatus"] isEqualToString:@"9000"]) {
                [NotificationCenter postNotificationName:kPaySuccessNotification object:@{@"payType": GetPayType(RGPayTypeAlipay)}];
            } else {
                [NotificationCenter postNotificationName:kPayFailNotification object:@{@"payType": GetPayType(RGPayTypeAlipay)}];
            }
        }];
        return YES;
    }

    // Handle custom scheme "wifiesim" deep links
    // Handle custom scheme "wifiesim" deep links
    if ([url.scheme isEqualToString:@"wifiesim"]) {
        __block BOOL refresh = NO; // Use a block variable to determine if refresh is needed
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
        
        // Parse query parameters
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([item.name isEqualToString:@"refresh"] && item.value.length > 0) {
                @try {
                    refresh = [item.value intValue] == 1;
                } @catch (NSException *exception) {
                    // Handle exceptions if needed
                }
            }
        }];
        
        // Handle specific paths in "wifiesim" deep links
        if ([@"home" isEqualToString:url.host]) {
            
            if ([@"/me" isEqualToString:url.path]) {
                if ([self hasLoginToken]) {
                    NSString *customURL = nil;

                    // Extract the custom URL from query parameters
                    for (NSURLQueryItem *item in urlComponents.queryItems) {
                        if ([item.name isEqualToString:@"url"]) {
                            customURL = item.value;
                            break;
                        }
                    }

                    // Switch to the "me" tab
                    [[Utility topViewController].tabBarController setSelectedIndex:2];

                    // If there's a custom URL, load it after switching tabs
                    if (customURL.length > 0) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [NotificationCenter postNotificationName:kLoadCustomURLNotification object:customURL];
                        });
                    }

                    return YES;
                } else {
                    [[Utility topViewController].tabBarController setSelectedIndex:2];
                }
            }
            // Handle other "/home" paths
            if ([@"/area" isEqualToString:url.path]) {
                NSString *customURL = nil;

                // Extract the custom URL from query parameters
                for (NSURLQueryItem *item in urlComponents.queryItems) {
                    if ([item.name isEqualToString:@"url"]) {
                        customURL = item.value;
                        break;
                    }
                }

                // Switch to the "me" tab
                [[Utility topViewController].tabBarController setSelectedIndex:0];

                // If there's a custom URL, load it after switching tabs
                if (customURL.length > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [NotificationCenter postNotificationName:kLoadCustomURLNotification2 object:customURL]; // Chanage 2
                    });
                }

                return YES;
            } else if ([@"/esim" isEqualToString:url.path]) {
                [[Utility topViewController].tabBarController setSelectedIndex:1];
            }
            return YES;
        }
        return YES;
    }

    // Handle other deep links
    NSDictionary *queryParams = [[url.query stringByRemovingPercentEncoding] DPL_parametersFromQueryString];
    [WBGRouter openURL:url.host withParam:queryParams];
    return YES;
}

/*
 else if ([@"/promo" isEqualToString:url.path]) { // New deep link
     [[Utility topViewController].tabBarController setSelectedIndex:2];
     NSString *promoURL = @"https://esimtest.jetfimobile.com/promo-code?entry=MEMBER";
     [WBGRouter openURL:kDeepLinkUrlRGCommonWebViewController withParam:promoURL];
 } else if ([@"/voucher" isEqualToString:url.path]) { // New deep link
     NSString *voucherURL = @"https://esimtest.jetfimobile.com/promo-dataPlan";
     [WBGRouter openURL:kDeepLinkUrlRGCommonWebViewController withParam:voucherURL];
 }
    wifiesim://home/me?url=https://esimtest.jetfimobile.com/promo-code?entry=MEMBER
    wifiesim://home/area?url=https://esimtest.jetfimobile.com/promo-dataPlan
 */


#pragma mark - Core Data stack
@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"RedteaGo"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
//                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support
- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
