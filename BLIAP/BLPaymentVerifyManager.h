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

@class BLPaymentVerifyManager, BLPaymentVerifyTask, BLPaymentTransactionModel;

NS_ASSUME_NONNULL_BEGIN

@protocol BLPaymentVerifyManagerDelegate<NSObject>

@required

/**
 * 收据验证收到结果, 验证结果为`收据有效`.
 *
 * @param paymentVerifyManager   当前验证 manager.
 * @param transactionIdentifier  交易唯一标识.
 */
- (void)paymentVerifyManager:(BLPaymentVerifyManager *)paymentVerifyManager paymentTransactionVerifyValid:(NSString *)transactionIdentifier;

/**
 * 收据验证收到结果, 验证结果为`收据无效`.
 *
 * @param paymentVerifyManager   当前验证 manager.
 * @param transactionIdentifier  交易唯一标识.
 */
- (void)paymentVerifyManager:(BLPaymentVerifyManager *)paymentVerifyManager paymentTransactionVerifyInvalid:(NSString *)transactionIdentifier;

/**
 * 请求失败或者后台和苹果服务器验证失败.
 *
 * @warning 此时应该刷新收据数据.
 *
 * @param paymentVerifyManager   当前验证 manager.
 */
- (void)paymentVerifyManagerRequestFailed:(BLPaymentVerifyManager *)paymentVerifyManager;

@end

@interface BLPaymentVerifyManager : NSObject

/**
 * Delegate.
 */
@property(nonatomic, weak, nullable) id<BLPaymentVerifyManagerDelegate> delegate;

/**
 * 当前正在验证的 task.
 */
@property(nonatomic, strong, readonly, nullable) BLPaymentVerifyTask *currentVerifingTask;

/**
 * userID.
 */
@property(nonatomic, copy, readonly) NSString *userid;

/**
 * 初始化方法.
 */
- (instancetype)initWithUserID:(NSString *)userid NS_DESIGNATED_INITIALIZER;

/**
 * 更新收据信息.
 */
- (void)refreshTransactionReceiptData:(NSData *)transactionReceiptData;

/**
 * ⚠️ 开始支付凭证验证队列(开始验证之前, 必须保证收据不为空).
 */
- (void)startPaymentTransactionVerifingIfNeed;

/**
 * 添加需要验证的 model.
 */
- (void)appendPaymentTransactionModel:(BLPaymentTransactionModel *)transactionModel;

/**
 * 指定交易标识的交易是否已经持久化到了 keychain 中了.
 */
- (BOOL)transactionDidStoreInKeyChainWithTransactionIdentifier:(NSString *)transactionIdentifier;

/**
 * 是否所有的待验证任务都完成了.
 */
- (BOOL)didNeedVerifyQueueClearedForCurrentUser;

/**
 * 取消所有的待验证队列的执行.
 */
- (void)cancelAllTasks;

@end

NS_ASSUME_NONNULL_END
