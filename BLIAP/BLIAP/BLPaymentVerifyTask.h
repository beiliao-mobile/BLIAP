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

#import <UIKit/UIKit.h>

@class BLPaymentTransactionModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BLPaymentVerifyTaskState) { // task 状态.
    BLPaymentVerifyTaskStateDefault = 0, // 初始化状态.
    BLPaymentVerifyTaskStateWaitingForServersResponse = 1, // 等待服务器响应.
    BLPaymentVerifyTaskStateFinished = 2,  // 完成.
    BLPaymentVerifyTaskStateCancel = 3 // 取消. 一旦取消, 这个 task 就不能再次调用 -start 方法重新执行了.
};

@class BLPaymentVerifyTask;

@protocol BLPaymentVerifyTaskDelegate<NSObject>

@required

/**
 * 验证收到结果通知, 验证收据有效.
 */
- (void)paymentVerifyTaskDidReceiveResponseReceiptValid:(BLPaymentVerifyTask *)task;

/**
 * 验证收到结果通知, 验证收据无效.
 */
- (void)paymentVerifyTaskDidReceiveResponseReceiptInvalid:(BLPaymentVerifyTask *)task;

/**
 * 验证请求出现错误, 需要重新请求.
 */
- (void)paymentVerifyTaskUploadCertificateRequestFailed:(BLPaymentVerifyTask *)task;

/**
 * 创建订单请求成功.
 *
 * @param task           当前任务.
 * @param orderNo        订单号.
 * @param priceTagString 价格字符串.
 * @param md5            交易收据是否有变动的标识.
 */
- (void)paymentVerifyTaskDidReceiveCreateOrderResponse:(BLPaymentVerifyTask *)task
                                               orderNo:(NSString *)orderNo
                                        priceTagString:(NSString *)priceTagString
                                                   md5:(NSString *)md5;

/**
 * 创建订单请求出现错误, 需要重新请求.
 */
- (void)paymentVerifyTaskCreateOrderRequestFailed:(BLPaymentVerifyTask *)task;

@end


@interface BLPaymentVerifyTask : NSObject

/**
 * Delegate.
 */
@property(nonatomic, weak, nullable) id<BLPaymentVerifyTaskDelegate> delegate;

/**
 * 交易凭证验证模型.
 */
@property(nonatomic, strong, nonnull, readonly) BLPaymentTransactionModel *transactionModel;

/**
 * task 状态.
 */
@property(nonatomic, assign, readonly) BLPaymentVerifyTaskState taskState;

/**
 * 收据.
 */
@property(nonatomic, strong, readonly) NSData *transactionReceiptData;

/**
 * 初始化方法.
 *
 * @warning 交易模型不能为空.
 *
 * @param paymentTransactionModel 交易模型.
 * @param transactionReceiptData  交易凭证.
 *
 * @return 当前实例.
 */
- (instancetype)initWithPaymentTransactionModel:(BLPaymentTransactionModel *)paymentTransactionModel transactionReceiptData:(NSData *)transactionReceiptData NS_DESIGNATED_INITIALIZER;

/**
 * 开始执行当前 task.
 *
 * @warning task 一旦取消, 这个 task 就不能再次调用 -start 方法重新执行了.
 */
- (void)start;

/**
 * 取消当前 task.
 *
 * @warning task 一旦取消, 这个 task 就不能再次调用 -start 方法重新执行了.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
