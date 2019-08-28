//
//  NSThread+GCD.h
//  XKNotificationCenter_Example
//
//  Created by ALLen、 LAS on 2019/8/28.
//  Copyright © 2019 RyanMans. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSThread (GCD)

/**
 是否是主线程
 
 @return yes／no
 */
BOOL isMainThread();

/**
 *  主线程
 *
 *  @param block  主线程
 */
void runBlockWithMain(dispatch_block_t block);

/**
 *  异步线程
 *
 *  @param block  异步执行
 */
void runBlockWithAsync(dispatch_block_t block);

/**
 *  先异步 后同步
 *
 *  @param asyncBlock  异步
 *  @param syncBlock   同步
 */
void runBlock(dispatch_block_t asyncBlock, dispatch_block_t syncBlock);


/**
 延时后调用，主线程
 
 @param time 时间， 0.5
 @param block 主线程
 
 */
void runBlockWithAsyncAfter(float time, dispatch_block_t block);

@end

NS_ASSUME_NONNULL_END
