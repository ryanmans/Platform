//
//  XKPushServiceManager.h
//  极光推送
//
//  Created by ALLen、 LAS on 2019/8/28.
//  Copyright © 2019 ALLen、 LAS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//推送服务管理
@interface XKPushServiceManager : NSObject

//单例
+ (XKPushServiceManager *)shareManager;

//初始化配置
- (void)registeredConfigurePushWithOptions:(NSDictionary *)launchOptions;

//判断是否打开推送
- (BOOL)isOpenRemoteNotification;

//关闭推送
- (void)unregisterRemoteNotifications;

//重置角标
- (void)resetBadge;

//移除推送 (支持iOS10，并兼容iOS10以下版本)
- (void)removeNotification;

//注册设备
- (void)registerDeviceToken:(NSData *)deviceToken;

//处理收到的 APNs 消息
- (void)handleReceiveRemoteNotification:(NSDictionary*)notification;

//iOS7及以上系统，接收到推送消息
- (void)handleReceiveRemoteNotification:(NSDictionary*)notification fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler;

//处理本地消息
- (void)handleLocalNotificationForRemotePush:(UILocalNotification*)notification;

@end

NS_ASSUME_NONNULL_END
