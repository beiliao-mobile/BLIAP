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

#import <UICKeyChainStore/UICKeyChainStore.h>
#import "BLWalletCompat.h"

NS_ASSUME_NONNULL_BEGIN

@class BLPaymentTransactionModel;

@protocol BLWalletTransactionModelsSaveProtocol<NSObject>

@optional

/**
 * 存储交易模型.
 *
 * @param models 交易模型. @see `BLPaymentTransactionModel`
 * @param userid 用户 id.
 */
- (void)bl_savePaymentTransactionModels:(NSArray<BLPaymentTransactionModel *> *)models
                                forUser:(NSString *)userid;

/**
 * 删除指定 `transactionIdentifier` 的交易模型.
 *
 * @param transactionIdentifier 交易模型唯一标识.
 * @param userid                用户 id.
 *
 * @return 是否删除成功. 失败的原因可能是因为标识无效(已存储数据中没有指定的标识的数据).
 */
- (BOOL)bl_deletePaymentTransactionModelWithTransactionIdentifier:(NSString *)transactionIdentifier
                                                          forUser:(NSString *)userid;

/**
 * 删除所有的 `transactionIdentifier` 交易模型.
 *
 * @param userid 用户 id.
 */
- (void)bl_deleteAllPaymentTransactionModelsIfNeedForUser:(NSString *)userid;

/**
 * 获取所有交易模型, 并排序.
 *
 * @return models 交易模型. @see `BLPaymentTransactionModel`
 * @param userid  用户 id.
 */
- (NSArray<BLPaymentTransactionModel *> * _Nullable)bl_fetchAllPaymentTransactionModelsSortedArrayUsingComparator:(NSComparator NS_NOESCAPE _Nullable)cmptr
                                                                                                          forUser:(NSString *)userid
                                                                                                            error:(NSError * __nullable __autoreleasing * __nullable)error;

/**
 * 获取所有交易模型.
 *
 * @param userid 用户 id.
 *
 * @return models 交易模型. @see `BLPaymentTransactionModel`
 */
- (NSArray<BLPaymentTransactionModel *> * _Nullable)bl_fetchAllPaymentTransactionModelsForUser:(NSString *)userid
                                                                                         error:(NSError * __nullable __autoreleasing * __nullable)error;

/**
 * 改变某笔交易的验证次数.
 *
 * @param transactionIdentifier 交易模型唯一标识.
 * @param modelVerifyCount      交易验证次数.
 * @param userid                用户 id.
 */
- (void)bl_updatePaymentTransactionModelStateWithTransactionIdentifier:(NSString *)transactionIdentifier
                                                      modelVerifyCount:(NSUInteger)modelVerifyCount
                                                               forUser:(NSString *)userid;

/**
 * 存储某笔交易的订单号和订单价格以及 md5 值.
 *
 * @param transactionIdentifier 交易模型唯一标识.
 * @param orderNo               订单号.
 * @param priceTagString        订单价格.
 * @param md5                   交易收据是否有变动的标识.
 * @param userid                用户 id.
 */
- (void)bl_savePaymentTransactionModelWithTransactionIdentifier:(NSString *)transactionIdentifier
                                                        orderNo:(NSString *)orderNo
                                                 priceTagString:(NSString *)priceTagString
                                                            md5:(NSString *)md5
                                                        forUser:(NSString *)userid;

@end

/**
 * 存储结构为: dict - set - model.
 *
 * 第一层 data, 是字典的归档数据.
 * 第二层字典, 以 userid 为 key, set 的归档 data.
 * 第二层集合, 是所有 model 的归档数据.
 */
@interface BLWalletKeyChainStore : UICKeyChainStore<BLWalletTransactionModelsSaveProtocol>

+ (BLWalletKeyChainStore *)keyChainStoreWithService:(NSString *_Nullable)service;

@end

NS_ASSUME_NONNULL_END

