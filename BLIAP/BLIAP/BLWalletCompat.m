//
//  BLWalletCompat.m
//  ACReuseQueue
//
//  Created by NewPan on 2017/12/4.
//

#import "BLWalletCompat.h"

// 验证收到结果通知, 验证收据有效, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification = @"com.ibeiliao.payment.verify.receive.response.valid.note.www";
// 验证收到结果通知, 验证收据无效, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification = @"com.ibeiliao.payment.verify.receive.response.invalid.note.www";;
// 验证请求出现错误, 需要重新请求, objc 为 task 本身.
NSString *const BLPaymentVerifyTaskUploadCertificateRequestFailedNotification = @"com.ibeiliao.payment.verify.request.failed.note.www";
// 创建订单请求成功通知, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
NSString *const BLPaymentVerifyTaskCreateOrderDidSuccessedNotification = @"com.ibeiliao.payment.createorder.request.success.note.www";
// 创建订单请求失败错误, objc 为 task 本身, 不要强持有 task 对象, task 会在使用以后释放.
NSString *const BLPaymentVerifyTaskCreateOrderRequestFailedNotification = @"com.ibeiliao.payment.createorder.request.failed.note.www";

// 用户选择了取消交易.
NSString *const BLPaymentManagerPaymentFailedNotification = @"com.ibeiliao.payment.failed.note.www";
// 交易验证成功, 弹出充值成功提醒, 用户点选 OK.
NSString *const BLPaymentUserDidClickOKAfterAlertNotification = @"com.ibeiliao.payment.verify.user.click.ok.note.www";;

// 验证已经验证过的交易时, 请求间隔步长因子, 单位为秒.
NSTimeInterval const BLPaymentVerifyUploadReceiptDataIntervalDelta = 10;
// 验证已经验证过的交易时, 请求间隔最大值, 单位为秒.
NSTimeInterval const BLPaymentVerifyUploadReceiptDataMaxIntervalDelta = 60;

// 测试使用清空所有未完成的交易.
NSString *const BLClearAllUnfinishedTransiactionNotification = @"com.ibeiliao.payment.clear.all.unfinished.transication.note.www";
