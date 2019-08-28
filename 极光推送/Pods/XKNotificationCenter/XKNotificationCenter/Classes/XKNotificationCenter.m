//
//  XKNotificationCenter.m
//  XKNotificationCenter_Example
//
//  Created by ALLen、 LAS on 2019/8/28.
//  Copyright © 2019 RyanMans. All rights reserved.
//

#import "XKNotificationCenter.h"

//消息对象集合
static NSMutableDictionary *_allObserverTask;
@interface XKNotificationObserver : NSObject
@property (nonatomic,weak,readonly)id observer;
@end

@implementation XKNotificationObserver
+ (XKNotificationObserver*)notificationObserver:(id)observer{
    return [[XKNotificationObserver alloc] initWithObserver:observer];
}

- (instancetype)initWithObserver:(id)observer{
    self = [super init];
    if (self) {
        _observer = observer;
    }
    return self;
}
@end

@implementation XKNotificationCenter

//存储着所有的请求task数组
+ (NSMutableDictionary *)allObserverTask {
    if (!_allObserverTask) {
        _allObserverTask = [[NSMutableDictionary alloc] init];
    }
    return _allObserverTask;
}

//添加消息监听对象
+ (void)addNotificationObserver:(id<XKNotificationCenterDelegate>)delegate name:(NSString *)name{
    XKNotificationObserver * observer = [XKNotificationObserver notificationObserver:delegate];
    NSMutableArray * groups = [self allObserverTask][name];
    if (!groups) {
        groups = [NSMutableArray new];
        [[self allObserverTask] setObject:groups forKey:name];
    }
    [groups addObject:observer];
}

//发送消息
+ (void)postNotification:(NSString *)name parameters:(id)parameters{
    if (isMainThread()) {
        runBlockWithAsync(^{
            [self postNotification:name parameters:parameters];
        });
        return;
    }
    NSMutableArray * groups = [self allObserverTask][name];
    [groups enumerateObjectsUsingBlock:^(XKNotificationObserver *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<XKNotificationCenterDelegate>delegate = obj.observer;
        [delegate receivedNotificationName:name observer:obj.observer parameters:parameters];
    }];
}
@end

