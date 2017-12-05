/*
 * This file is part of the BLIAP package.
 * (c) NewPan <13246884282@163.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Click https://github.com/newyjp
 * or http://www.jianshu.com/users/e2f2d779c022/latest_articles to contact me.
 */

#ifndef BLWalletCompat_h
#define BLWalletCompat_h

#import <UIKit/UIKit.h>

static NSString *BLWalletErrorDomain = @"com.ibeiliao.wallet.error.www";

// 某笔待验证交易的验证状态。
typedef NS_ENUM(NSUInteger, BLPaymentTransactionModelState) {
    BLPaymentTransactionModelStateDefault = 0, // 初始状态， 从未和后台验证过.
    BLPaymentTransactionModelStateNeedRetry = 1 // 等待重试， 至少和后台验证过一次，并且未能验证当前交易的状态.
};

// 开始发送验证时的通知, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskStartNotification;
// 验证收到结果通知, 验证收据有效, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification;
// 验证收到结果通知, 验证收据无效, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification;
// 验证请求出现错误, 需要重新请求, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskRequestFailedNotification;

// 验证已经验证过的交易时, 请求间隔步长因子, 单位为秒.
UIKIT_EXTERN NSTimeInterval const BLPaymentVerifyUploadReceiptDataIntervalDelta;

#endif /* BLWalletCompat_h */
