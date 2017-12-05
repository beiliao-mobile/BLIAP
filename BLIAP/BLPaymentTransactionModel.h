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
#import "BLWalletCompat.h"

NS_ASSUME_NONNULL_BEGIN

@interface BLPaymentTransactionModel : NSObject<NSCoding>

#pragma mark - Properties

/**
 * 事务 id.
 */
@property(nonatomic, copy, nonnull, readonly) NSString *transactionIdentifier;

/**
 * 交易时间(添加到交易队列时的时间).
 */
@property(nonatomic, strong, readonly) NSDate *transactionDate;

/**
 * 商品 id.
 */
@property(nonatomic, copy, readonly) NSString *productIdentifier;

/**
 * 后台配置的订单号.
 */
@property(nonatomic, copy, readonly) NSString *orderNo;

/*
 * 任务被验证的次数.
 * 初始状态为 0,从未和后台验证过.
 * 当次数大于 1 时, 至少和后台验证过一次，并且未能验证当前交易的状态.
 */
@property(nonatomic, assign) NSUInteger modelVerifyCount;

#pragma mark - Method

/**
 * 初始化方法(没有收据的).
 *
 * @warning: 所有数据都必须有值, 否则会报错, 并返回 nil.
 *
 * @param productIdentifier       商品 id.
 * @param transactionIdentifier   事务 id.
 * @param transactionDate         交易时间(添加到交易队列时的时间).
 * @param orderNo                 订单号.
 */
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                    transactionIdentifier:(NSString *)transactionIdentifier
                          transactionDate:(NSDate *)transactionDate
                                  orderNo:(NSString *)orderNo;

@end

NS_ASSUME_NONNULL_END
