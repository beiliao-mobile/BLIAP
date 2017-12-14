/*
 * This file is part of the BLIAP package.
 * (c) NewPan <13246884282@163.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Click https://github.com/newyjp
 * or https://juejin.im/user/5824ab9ea22b9d006709d54e to contact me.
 */

#ifndef BLWalletCompat_h
#define BLWalletCompat_h

#import <UIKit/UIKit.h>

static NSString *BLWalletErrorDomain = @"com.ibeiliao.wallet.error.www";

// 验证收到结果通知, 验证收据有效, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification;
// 验证收到结果通知, 验证收据无效, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification;
// 验证请求出现错误, 需要重新请求, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskUploadCertificateRequestFailedNotification;
// 创建订单请求成功通知, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskCreateOrderDidSuccessedNotification;
// 创建订单请求失败错误, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
UIKIT_EXTERN NSString *const BLPaymentVerifyTaskCreateOrderRequestFailedNotification;

// 用户选择了取消交易.
UIKIT_EXTERN NSString *const BLPaymentManagerPaymentFailedNotification;
// 交易验证成功, 弹出充值成功提醒, 用户点选 OK.
UIKIT_EXTERN NSString *const BLPaymentUserDidClickOKAfterAlertNotification;

// 验证已经验证过的交易时, 请求间隔步长因子, 单位为秒.
UIKIT_EXTERN NSTimeInterval const BLPaymentVerifyUploadReceiptDataIntervalDelta;
// 验证已经验证过的交易时, 请求间隔最大值, 单位为秒.
UIKIT_EXTERN NSTimeInterval const BLPaymentVerifyUploadReceiptDataMaxIntervalDelta;

// 测试使用清空所有未完成的交易.
UIKIT_EXTERN NSString *const BLClearAllUnfinishedTransiactionNotification;

#endif /* BLWalletCompat_h */
