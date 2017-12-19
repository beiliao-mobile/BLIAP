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
@property(nonatomic, copy, nullable) NSString *orderNo;

/**
 * 价格字符.
 */
@property(nonatomic, copy, nullable) NSString *priceTagString;

/**
 * 交易收据是否有变动的标识.
 */
@property(nonatomic, copy, nullable) NSString *md5;

/*
 * 任务被验证的次数.
 * 初始状态为 0,从未和后台验证过.
 * 当次数大于 1 时, 至少和后台验证过一次，并且未能验证当前交易的状态.
 */
@property(nonatomic, assign) NSUInteger modelVerifyCount;

/**
 * 是否已经在后台验证过并且有了结果(成功或者失败).
 *
 * @warning: 1. 确实会出现明明有未成功的交易, 但是在苹果的未完成交易列表里取不到. 此时应该将这笔订单的状态更改过来.
 *           2. 这个值默认是 NO, 代表没有在后台验证过, 直到在后台验证过, 然后去 IAP 未完成交易列表中取值的取不到这笔订单的时候才会将订单的状态改为 YES.
 *           3. 对于验证有结果并且能在 IAP 的未完成交易中取到值得交易, 直接就会从 keychain 中删除.
 */
@property(nonatomic, assign) BOOL isTransactionValidFromService;

#pragma mark - Method

/**
 * 初始化方法(没有收据的).
 *
 * @warning: 所有数据都必须有值, 否则会报错, 并返回 nil.
 *
 * @param productIdentifier       商品 id.
 * @param transactionIdentifier   事务 id.
 * @param transactionDate         交易时间(添加到交易队列时的时间).
 */
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                    transactionIdentifier:(NSString *)transactionIdentifier
                          transactionDate:(NSDate *)transactionDate;

@end

NS_ASSUME_NONNULL_END
