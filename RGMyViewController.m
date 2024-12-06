//
//  RGMyViewController.m
//  JetFi WIFI_eSIM
//
//  Created by UnknownFFF on 2023/12/25.
//  Copyright © 2019 Redtea. All rights reserved.
//  首页

#import "RGMyViewController.h"


@interface RGMyViewController()

@end

@implementation RGMyViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[RGEventAnalysis sharedInstance] sendEvent:RGEventAnalysisClickUserProfile];
}

#pragma mark - NotificationCenter通知
- (void)addObservers {
    [NotificationCenter addObserver:self selector:@selector(loadUserInfoNotification:) name:kloadUserInfoNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(loginSuccessNotification:) name:kLoginSuccessNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(onReloadUrl:) name:kReloadUrlNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(onLoadCustomUrl:) name:kLoadCustomURLNotification object:nil]; // Add observer for custom URL
}

- (void)loadUserInfoNotification:(NSNotification *)notification {
    if ([self.webView.URL path].length == 0 || [[self.webView.URL path] isEqualToString:@"/"]) {
        [self loadDatas];
    }
}

- (void)loginSuccessNotification:(NSNotification *)notification {
    [self loadDatas];
}

- (void)onReloadUrl:(NSNotification *)notification {
    if ([@"2" isEqualToString: notification.object]) {
        [self loadDatas];
    }
}

// New method to handle loading a custom URL
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

- (void)loadDatas {
    if (self.webView.URL && self.webView.URL.absoluteString.length > 0) {
        NSLog(@"WebView is already loading a URL: %@", self.webView.URL.absoluteString);
        return; // Do not reload the default URL if a custom URL is already loaded
    }

    NSString *myViewUrl = kMyViewUrl;
    if ([@"https://esim.redteatest.com" isEqualToString:HostURL]) {
        myViewUrl = kMyViewUrl_QA;
    }
    
    myViewUrl = [RGPublicSettingConfig.currentSetting getUrlWithLanguage:myViewUrl];
    NSLog(@"myViewUrl: %@", myViewUrl);
    NSURL *pathURL = [NSURL URLWithString:myViewUrl];
    
    [RGProgressHUD showHUD];
    NSURLRequest *request = [NSURLRequest requestWithURL:pathURL];
    [self.webView loadRequest:request];
}

@end
