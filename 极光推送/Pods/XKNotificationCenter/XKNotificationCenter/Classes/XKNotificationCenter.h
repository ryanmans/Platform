//
//  XKNotificationCenter.h
//  XKNotificationCenter_Example
//
//  Created by ALLen、 LAS on 2019/8/28.
//  Copyright © 2019 RyanMans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSThread+GCD.h"

NS_ASSUME_NONNULL_BEGIN

@protocol XKNotificationCenterDelegate;

//消息中心
@interface XKNotificationCenter : NSObject

/**
 *  添加监听者
 *
 *  @param delegate   监听对象
 *  @param name      消息类型
 */
+ (void)addNotificationObserver:(id<XKNotificationCenterDelegate>)delegate name:(NSString *)name;

/**
 *  发送消息(异步)
 *
 *  @param name         消息类型
 *  @param parameters   发送的参数
 */
+ (void)postNotification:(NSString *)name parameters:(id _Nullable)parameters;
@end


//代理事件
@protocol XKNotificationCenterDelegate <NSObject>

/**
 *  接收消息(异步)
 *
 *  @param name      消息类型
 *  @param observer   监听消息的对象
 *  @param parameters   发送的参数
 */
- (void)receivedNotificationName:(NSString*)name observer:(id)observer parameters:(id _Nullable)parameters;

@end

NS_ASSUME_NONNULL_END
