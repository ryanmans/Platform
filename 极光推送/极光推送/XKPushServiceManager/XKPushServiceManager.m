//
//  XKPushServiceManager.m
//  极光推送
//
//  Created by ALLen、 LAS on 2019/8/28.
//  Copyright © 2019 ALLen、 LAS. All rights reserved.
//

#import "XKPushServiceManager.h"

@interface XKPushServiceManager ()<JPUSHRegisterDelegate>
@property (nonatomic,strong)NSDictionary * pushMessageDataSource; //存放推送的消息类型
@end

@implementation XKPushServiceManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pushMessageDataSource = @{};
    }
    return self;
}

+ (XKPushServiceManager *)shareManager{
    static XKPushServiceManager * pusher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pusher = [XKPushServiceManager new];
    });
    return pusher;
}

//基本配置
- (void)registeredConfigurePushWithOptions:(NSDictionary *)launchOptions{
    JPUSHRegisterEntity * jpEntity = [JPUSHRegisterEntity new];
    jpEntity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionSound;
    
    //注册极光推送
    [JPUSHService registerForRemoteNotificationConfig:jpEntity delegate:self];
    
    //启动极光SDK, 如不需要使用IDFA，advertisingIdentifier 可为nil,apsForProduction 开发为no，正式 为 yes ／／XK_JPush_Channel
    [JPUSHService setupWithOption:launchOptions appKey:APP_PUSH_KEY channel:@"App Store" apsForProduction:USE_RELEASE_API advertisingIdentifier:nil];
    
    //app进程被杀死后，启动app获取推送消息
    NSDictionary * remoteInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteInfo) {
        [self distributeReceiveRemoteNotification:remoteInfo];
    }
    
    //监听自定义消息内容
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkDidReceiveMessageNotification:) name:kJPFNetworkDidReceiveMessageNotification object:nil];
}

//判断是否打开推送
- (BOOL)isOpenRemoteNotification{
    BOOL isOpenNotification;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        isOpenNotification = !([[UIApplication sharedApplication]currentUserNotificationSettings].types == 0) ;
        
    } else {
        isOpenNotification = !([[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone);
    }
    return isOpenNotification;
}

//关闭推送
- (void)unregisterRemoteNotifications{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJPFNetworkDidCloseNotification object:nil];
}

//重置角标
- (void)resetBadge{
    [JPUSHService resetBadge];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

//移除推送 (支持iOS10，并兼容iOS10以下版本)
- (void)removeNotification{
    [JPUSHService removeNotification:nil];
}

//注册设备
- (void)registerDeviceToken:(NSData *)deviceToken{
    [JPUSHService registerDeviceToken:deviceToken];
}

//iOS6及以下系统,处理收到的 APNs 消息
- (void)handleReceiveRemoteNotification:(NSDictionary*)notification{
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [notification valueForKey:@"aps"];
    NSString *content = [aps valueForKey:@"alert"]; //推送显示的内容
    NSNumber * badge = [aps valueForKey:@"badge"]; //badge 数量
    NSString *sound = [aps valueForKey:@"sound"]; //播放的声音
    
    // 取得 Extras 字段内容
    NSString *customizeField1 = [notification valueForKey:@"customizeExtras"]; //服务端中 Extras 字段，key 是自己定义的
    NSLog(@"content =[%@], badge=[%@], sound=[%@], customize field  =[%@]",content,badge,sound,customizeField1);
    
    [self handleRemoteNotification:notification];
}

//iOS7及以上系统，接收到推送消息
- (void)handleReceiveRemoteNotification:(NSDictionary*)notification fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{
    [self handleRemoteNotification:notification];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        [self clickRemoteNotification:notification];//活跃情况下、点击推送消息事件
    }
    completionHandler ? completionHandler(UIBackgroundFetchResultNewData) : nil;
}

//处理本地消息
- (void)handleLocalNotificationForRemotePush:(UILocalNotification*)notification{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    [JPUSHService showLocalNotificationAtFront:notification identifierKey:nil];
#endif
}

//处理收到的自定义消息(应用内消息)
- (void)handleNetworkDidReceiveMessageNotification:(NSNotification*)notification{
    [self distributeReceiveRemoteNotification:[[notification userInfo] valueForKey:@"extras"]];
}

//处理收到的 APNs 消息
- (void)handleRemoteNotification:(NSDictionary *)remoteInfo{
    [JPUSHService handleRemoteNotification:remoteInfo];
    [self distributeReceiveRemoteNotification:remoteInfo];
    [self printLogRemoteNotification:remoteInfo];
}

//派发接受到的APNS远程消息
- (void)distributeReceiveRemoteNotification:(NSDictionary*)remoteInfo{
    runBlockWithMain(^{
        NSString * message = self->_pushMessageDataSource[remoteInfo[@"type"]];
        if (message && message.length) {
            [XKNotificationCenter postNotification:message parameters:remoteInfo];
        }
    });
}

// 点击收到的APNS消息
- (void)clickRemoteNotification:(NSDictionary*)remoteInfo{
    runBlockWithMain(^{
        if (!remoteInfo) return ;
        //将推送的消息传给当前活跃的控制器
        [XKNotificationCenter postNotification:MsgTypeJPushMessageNeedReload parameters:remoteInfo];
    });
}

//打印推送消息日志
- (void)printLogRemoteNotification:(NSDictionary*)remoteInfo{
    if (!remoteInfo.count) return;
    NSString * description = [[remoteInfo description] stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    description = [description stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    description = [[@"\"" stringByAppendingString:description] stringByAppendingString:@"\""];
    NSData * tempData = [description dataUsingEncoding:NSUTF8StringEncoding];
    description = [NSPropertyListSerialization propertyListWithData:tempData
                                                            options:NSPropertyListImmutable
                                                             format:NULL
                                                              error:NULL];
    NSLog(@"收到远程通知:%@", description);
}

#pragma mark --  JPUSHRegisterDelegate
//iOS10 - 前台得到的的通知对象
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler{
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self handleRemoteNotification:notification.request.content.userInfo];
    }else{
        //本地通知
        UNNotificationContent *content = notification.request.content; // 收到推送的消息内容
        NSNumber *badge = content.badge;  // 推送消息的角标
        NSString *body = content.body;    // 推送消息体
        UNNotificationSound *sound = content.sound;  // 推送消息的声音
        NSString *subtitle = content.subtitle;  // 推送消息的副标题
        NSString *title = content.title;  // 推送消息的标题
        NSLog(@"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,notification.request.content.userInfo);
    }
    //UNNotificationPresentationOptionBadge 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    completionHandler ? completionHandler(UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert) : nil;
}

//iOS10 - 后台得到的的通知对象(当用户点击通知栏的时候)
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self handleRemoteNotification:userInfo]; //接收消息
        [self clickRemoteNotification:userInfo]; //点击消息
    }
    completionHandler ? completionHandler() : nil;  // 系统要求执行这个方法
}

//当从应用外部通知界面或通知设置界面进入应用时，该方法将回调
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification{
    if (notification) {
        //从通知界面直接进入应用
    }else{
        
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kJPFNetworkDidReceiveMessageNotification object:nil];
}
@end
