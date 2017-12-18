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

// @warning ⚠️ 越狱手机不允许 IAP 支付功能.

/**
 * 可能存在的问题: ❌
 *
 * 1. 没验证完, 用户更换了 APP ID, 导致 keychain 被更改.
 * 2. 订单没有拿到收据, 此时用户更换了手机, 那么此时收据肯定是拿不到的.
 */

/**
 * **交易凭证持久化** 说明:
 *
 * @see `BLPaymentTransactionModel`, `UICKeyChainStore`.
 *
 * 1. 当 APP 和服务器通讯, 等待服务器去苹果服务器查询收据真伪时可能出现失败, 而苹果只在每次 APP 启动的时候才触发一次事务查询代理, 所以必须自己实现一套查询收据查询机制.
 * 2. 当交易状态变为 SKPaymentTransactionStatePurchased(支付完成) 时, 就会将交易模型数据持久化到 keychain.
 * 3. 持久化以后, 有重试查询收据队列触发服务器向苹果服务器进行收据有效性查询, 并且根据后台返回的结果对交易凭证对象状态进行更新(finish 掉).
 * 4. 当查询收据有效以后, 将从 keychain 里移除掉对应的交易模型数据 😁.
 * 5. 当查询收据有效无效, 将从 keychain 里移除掉对应的交易模型数据 😭.
 *
 * @reference: http://zhangtielei.com/posts/blog-iap.html
 * @reference: http://blog.csdn.net/jiisd/article/details/50527426
 * @reference: http://blog.csdn.net/jiisd/article/details/50527426
 * @reference: https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnectInAppPurchase_Guide_SCh/Chapters/TestingInAppPurchases.html
 * @reference: https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
 */

/**
 * **收据有效性查询队列** 说明:
 *
 * @see `BLPaymentVerifyManager`.
 *
 * 1. 队列管理者内部有一个需要等待上传的队列, 这个队列在管理者初始化的时候从 keychain 中恢复.
 * 2. 队列的每个对象是 `BLPaymentVerifyTask`, 每个 task 负责发起请求和后台通讯, 验证对应的交易收据是否有效.
 * 3. 每当一个 task 和后台通讯有结果(收据有效 / 无效 / 通讯失败), task 会把结果回到到队列管理者.
 * 4. 管理者根据当前运行的 task 的结果做出反应, 驱动下一个 task 的执行, 直到队列中没有 task.
 * 5. 当有新的交易进入到当前的队列中的时候, 行为路径为: 先持久化到 keychain, 再检查当前有没有正在执行的 task, 如果有, 插入到队列中等待 task 逐一执行(按照交易时间循序), 如果没有正在执行的 task, 直接开始验证.
 * 6. 第一次安装 APP 需要去 keychain 检查是否有没有验证的交易.
 */

@class SKProduct;

NS_ASSUME_NONNULL_BEGIN

/**
 * 获取商品信息回调.
 *
 * @param products 商品数组.
 * @param error    错误信息.
 */
typedef void(^BLPaymentFetchProductCompletion)(NSArray<SKProduct *>  * _Nullable products, NSError * _Nullable error);

@interface BLPaymentManager : NSObject

/**
 * 单例.
 */
@property(class, nonatomic, strong, readonly) BLPaymentManager *sharedManager;

/**
 * 单例方法.
 */
+ (instancetype)sharedManager;

/**
 * 是否所有的待验证任务都完成了.
 *
 * @warning error ⚠️ 退出前的警告信息(比如用户有尚未得到验证的订单).
 */
- (BOOL)didNeedVerifyQueueClearedForCurrentUser;

/**
 * 注销当前支付管理者.
 *
 * @warning ⚠️ 在用户退出登录时调用.
 */
- (void)logoutPaymentManager;

/**
 * 当前设备是否是越狱设备(越狱手机不允许 IAP 支付功能).
 */
- (BOOL)currentDeviceIsJailbroken;

/**
 * 开始支付事务监听, 并且开始支付凭证验证队列.
 *
 * @warning ⚠️ 请在用户登录时和用户重新启动 APP 时调用.
 *
 * @param userid 用户 ID.
 */
- (void)startTransactionObservingAndPaymentTransactionVerifingWithUserID:(NSString *)userid;

/**
 * 获取产品信息.
 *
 * @param productIdentifiers 产品标识.
 * @param completion         获取完成以后的回调(注意循环引用).
 */
- (void)fetchProductInfoWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers
                                    completion:(BLPaymentFetchProductCompletion)completion;

/**
 * 购买某个产品.
 *
 * @param product 产品实例.
 * @param error   错误.
 */
- (void)buyProduct:(SKProduct *)product error:(NSError * __nullable __autoreleasing * __nullable)error;

@end

NS_ASSUME_NONNULL_END
