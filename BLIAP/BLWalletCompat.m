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

#import <Foundation/Foundation.h>

// 开始发送验证时的通知, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskStartNotification = @"com.ibeiliao.payment.verify.start.note.www";
// 验证收到结果通知, 验证收据有效, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification = @"com.ibeiliao.payment.verify.receive.response.valid.note.www";
// 验证收到结果通知, 验证收据无效, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification = @"com.ibeiliao.payment.verify.receive.response.invalid.note.www";;
// 验证请求出现错误, 需要重新请求, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskRequestFailedNotification = @"com.ibeiliao.payment.verify.request.failed.note.www";

// 验证已经验证过的交易时, 请求间隔步长因子, 单位为秒.
NSTimeInterval const BLPaymentVerifyUploadReceiptDataIntervalDelta = 10;
