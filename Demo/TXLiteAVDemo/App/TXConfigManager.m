//
//  TXConfigManager.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/9/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Bugly/Bugly.h>
#import <Bugly/BuglyConfig.h>

#ifdef LIVE
#import "V2TXLivePremier.h"
#else
#import "TXLiveBase.h"
#endif

#ifdef ENABLE_UGC
#import "TXUGCBase.h"
#import "TELicenseCheck.h"
#endif

#ifdef ENABLE_TRTC
#import "TRTCCloud.h"
#endif

#if defined(TRTC) || defined(PROFESSIONAL)
#import <ToolKitBase/ToolKitBase.h>
#import <TRTCKit/TRTCKit.h>
#import "ProfileManager.h"
#endif

#import "AppLocalized.h"
#import "AppLogMgr.h"
#import "TCUtil.h"
#import "TXConfigManager.h"

#define BUGLY_APP_ID @"afaa33f835"

static TXConfigManager *_shareInstance = nil;

@interface TXConfigManager ()

@property(nonatomic, strong) NSDictionary *config;
@property(nonatomic, weak) id actionTarget;
@property(nonatomic, strong) NSMutableArray *routeArray;

@end

@implementation TXConfigManager

+ (instancetype)shareInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _shareInstance = [[TXConfigManager alloc] init];
        _shareInstance.routeArray = [NSMutableArray arrayWithCapacity:2];
    });
    return _shareInstance;
}

- (void)setMenuActionTarget:(id)object {
    self.actionTarget = object;
}

- (void)loadConfig {
    NSString *plistName;
#ifdef ENTERPRISE
    plistName = @"Enterprise";
#endif
    
#ifdef PROFESSIONAL
    plistName = @"Professional";
#endif
    
#ifdef ENABLE_INTERNATIONAL
    plistName = @"International";
#endif
    
#ifdef PLAYER
    plistName = @"Player";
#endif
    
#ifdef LIVE
    plistName = @"LIVE";
#endif
    
#ifdef TRTC
    plistName = @"TRTC";
#endif
    
#ifdef UGC
    plistName = @"UGC";
#endif
    
#ifdef SMART
    plistName = @"Smart";
#endif
    
#ifdef WECHATTOOLS
    plistName = @"WeChatTools";
#endif
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    _config = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
}

- (NSDictionary *)licenceConfig {
    return [_config objectForKey:@"licenceConfig"];
}

- (NSArray *)menusConfig {
    return [_config objectForKey:@"menuConfig"];
}

- (BOOL)isRelease {
    return [[_config objectForKey:@"isRelease"] boolValue];
}

- (BOOL)needCheckDevOpsVersion {
    if (_config[@"needCheckDevOpsVersion"]) {
        return [[_config objectForKey:@"needCheckDevOpsVersion"] boolValue];
    }
    return NO;
}

- (NSString *)devOpsAppName{
    NSDictionary *devOpsInfo = _config[@"devOpsConfig"];
    if (devOpsInfo && [devOpsInfo isKindOfClass:[NSDictionary class]]) {
        return devOpsInfo[@"appName"] ?: @"";
    }
    return @"";
}

- (NSString *)devOpsDownloadURL{
    NSDictionary *devOpsInfo = _config[@"devOpsConfig"];
    if (devOpsInfo && [devOpsInfo isKindOfClass:[NSDictionary class]]) {
        return devOpsInfo[@"downloadUrl"] ?: @"";
    }
    return @"";
}

- (void)setLicence {
#if !defined(PLAYER)
    NSString *licenceUrl = [self.licenceConfig objectForKey:@"licenceUrl"];
    NSString *licenceKey = [self.licenceConfig objectForKey:@"licenceKey"];
    //添加UGC模块的
#ifdef ENABLE_UGC
    [TXUGCBase setLicenceURL:licenceUrl key:licenceKey];
    [TELicenseCheck setTELicense:licenceUrl key:licenceKey completion:^(NSInteger authresult, NSString * _Nonnull errorMsg) {
                   if (authresult == TELicenseCheckOk) {
                        NSLog(@"鉴权成功");
                    } else {
                        NSLog(@"鉴权失败");
                    }
            }];
#endif
    
#ifdef ENABLE_PLAY
    [TXLiveBase setLicenceURL:licenceUrl key:licenceKey];
#endif
    
#endif

#if defined(PLAYER)
    NSString *licenceUrl = [self.licenceConfig objectForKey:@"licenceUrl"];
    NSString *licenceKey = [self.licenceConfig objectForKey:@"licenceKey"];
    [TXLiveBase setLicenceURL:licenceUrl key:licenceKey];
#endif
}

- (void)setLogConfig {
#ifdef ENABLE_TRTC
    [TRTCCloud setConsoleEnabled:NO];
    [TRTCCloud setLogLevel:TRTCLogLevelDebug];
    [TRTCCloud setLogDelegate:[AppLogMgr shareInstance]];
#else
#ifdef LIVE
    [V2TXLivePremier setObserver:[AppLogMgr shareInstance]];
    V2TXLiveLogConfig *logConf = [V2TXLiveLogConfig new];
    logConf.enableObserver = YES;
    [V2TXLivePremier setLogConfig:logConf];
#else
    [TXLiveBase sharedInstance].delegate = [AppLogMgr shareInstance];
    [TXLiveBase setConsoleEnabled:NO];
    [TXLiveBase setAppID:@"1252463788"];
#endif
#endif
}


- (void)initDebug {
    BOOL isFirstStart = [[NSUserDefaults standardUserDefaults] boolForKey:kIsFirstStart];
    if (isFirstStart) {
        //只设置一次
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsFirstStart];
    if ([self isRelease]) {
        //发布包默认关闭debug
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kMainMenuDEBUGSwitch];
    } else {
        //非发布包默认打开debug
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMainMenuDEBUGSwitch];
    }
}
- (void)setupBugly {
    // 启动bugly组件，bugly组件为腾讯提供的用于crash上报和分析的开放组件，如果您不需要该组件，可以自行移除
    BuglyConfig *config  = [[BuglyConfig alloc] init];
    if ([self isRelease]) {
        // Release版本Channel设置
        config.channel = @"LiteAV Release";
    } else {
#ifdef TRTC_EMBED
        config.channel = @"LiteAV TRTC_Refactoring"; // 重构打包Chanel设置
#else
        config.channel = @"LiteAV Debug"; // 其他模式，内部测试用
#endif
    }
#ifdef DEBUG
    config.debugMode = YES;
#endif
    config.version = [TXAppInfo appVersionWithBuild];
    [Bugly startWithAppId:BUGLY_APP_ID config:config];
    
}

- (NSMutableArray<CellInfo *> *)getMenuConfig {
    NSMutableArray<CellInfo *> *cellInfos = [[NSMutableArray alloc] initWithCapacity:2];
    NSArray *menusConfig = [self menusConfig];
    for (NSDictionary *menu in menusConfig) {
        bool debug = [menu objectForKey:@"debug"];
        if (debug && ![TCUtil getDEBUGSwitch]) {
            continue;
        }
        NSString *title = [menu objectForKey:@"title"];
        CellInfo *cellInfo = [[CellInfo alloc] init];
        bool isTrtc = [menu objectForKey:@"TRTC"];
        cellInfo.title = V2Localize(title);
        NSArray *subMenus = [menu objectForKey:@"subMenus"];
        NSMutableArray *subCells = [NSMutableArray array];
        for (NSDictionary *subMenu in subMenus) {
            NSString *subTitle = [subMenu objectForKey:@"title"];
            NSString *classStr = [subMenu objectForKey:@"class"];
            NSString *routeName = [subMenu objectForKey:@"route"];
            bool debug = [subMenu objectForKey:@"debug"];
            if (debug && ![TCUtil getDEBUGSwitch]) {
                continue;
            }
            if (isTrtc) {
                subTitle = TRTCLocalize(subTitle);
            } else {
                subTitle = V2Localize(subTitle);
            }
            if (classStr.length > 0) {
                CellInfo *subCellInfo = [CellInfo cellInfoWithTitle:subTitle
                                                controllerClassName:classStr];
                [subCells addObject:subCellInfo];
#if defined(TRTC) || defined(PROFESSIONAL)
            } else if (routeName.length > 0) {
                TKBaseRouter *route = [[NSClassFromString(routeName) alloc] initWithNavigation:self.navigation];
                if (isTrtc) {
                    NSString *userID = [ProfileManager shared].curUserID;
                    TRTCUserInfo *userInfo = [[TRTCUserInfo alloc] initWithUserId:userID];
                    route = [[NSClassFromString(routeName) alloc] initWithNavigation:self.navigation userInfo:userInfo];
                }
                [self.routeArray addObject:route];
                NSArray *entrances = [route entrances];
                [entrances enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    TKMainEntrance *entrance = obj;
                    CellInfo *subCellInfo = [CellInfo cellInfoWithTitle:entrance.title actionBlock:^{
                        entrance.action();
                    }];
                    [subCells addObject:subCellInfo];
                }];
#endif
            } else {
                __weak __typeof(self) weakSelf = self;
                CellInfo *subCellInfo =
                [CellInfo cellInfoWithTitle:subTitle
                                actionBlock:^{
                    NSString *method = [subMenu objectForKey:@"method"];
                    SEL sel = NSSelectorFromString(method);
                    if ([weakSelf.actionTarget respondsToSelector:sel]) {
                        IMP imp = [weakSelf.actionTarget methodForSelector:sel];
                        void (*func)(id, SEL) = (void *)imp;
                        func(weakSelf.actionTarget, sel);
                    }
                }];
                [subCells addObject:subCellInfo];
            }
        }
        cellInfo.subCells = subCells;
        [cellInfos addObject:cellInfo];
    }
    return cellInfos;
}

@end

