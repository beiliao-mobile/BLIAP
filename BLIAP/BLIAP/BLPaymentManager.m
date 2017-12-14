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

#import "BLPaymentManager.h"
#import <StoreKit/StoreKit.h>
#import "BLPaymentVerifyManager.h"
#import "BLPaymentTransactionModel.h"
#import "BLWalletCompat.h"
#import "BLJailbreakDetectTool.h"

@interface BLPaymentManager()<SKPaymentTransactionObserver, SKProductsRequestDelegate, BLPaymentVerifyManagerDelegate>

/**
 * 获取完成以后的回调(注意循环引用).
 */
@property(nonatomic, copy) BLPaymentFetchProductCompletion fetchProductCompletion;

/**
 * 收据有效性查询队列.
 */
@property(nonatomic, strong) BLPaymentVerifyManager *verifyManager;

/**
 * products.
 */
@property(nonatomic, strong) NSArray<SKProduct *> *products;

/**
 * 获取商品列表请求.
 */
@property(nonatomic, weak, nullable) SKProductsRequest *currentProductRequest;

@end

NSString *const kBLPaymentManagerKeychainStoreServiceKey = @"com.ibeiliao.payment.attachment.keychain.store.service.key.www";
@implementation BLPaymentManager

- (void)dealloc {
    if ([self currentDeviceIsJailbroken]) {
        return;
    }
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.fetchProductCompletion = nil;
    [self removeNotificationObserver];
    [self.verifyManager cancelAllTasks];
    self.verifyManager = nil;
}


#pragma mark - Public

static BLPaymentManager *_sharedManager = nil;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedManager) {
            _sharedManager = [BLPaymentManager new];
            // 添加监听进入前台通知.
            [_sharedManager addNotificationObserver];
        }
    });
    
    return _sharedManager;
}

- (BOOL)didNeedVerifyQueueClearedForCurrentUser {
    return [self.verifyManager didNeedVerifyQueueClearedForCurrentUser];
}

- (void)logoutPaymentManager {
    if ([self currentDeviceIsJailbroken]) {
        return;
    }
    if (self.currentProductRequest) {
        [self.currentProductRequest cancel];
        self.currentProductRequest = nil;
    }
    [self.verifyManager cancelAllTasks];
    self.verifyManager = nil;
    self.fetchProductCompletion = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (BOOL)currentDeviceIsJailbroken {
    return [BLJailbreakDetectTool detectCurrentDeviceIsJailbroken];
}

- (void)startTransactionObservingAndPaymentTransactionVerifingWithUserID:(NSString *)userid{
    NSAssert(!self.verifyManager, @"该方法只能在用户登录完成以后调用一次, 多次调用无效");
    if (self.verifyManager) {
        return;
    }
    
    if ([self currentDeviceIsJailbroken]) {
        return;
    }
    
    NSParameterAssert(userid);
    if (!userid) {
        return;
    }
    
    self.verifyManager = [[BLPaymentVerifyManager alloc] initWithUserID:userid];
    self.verifyManager.delegate = self;
    
    // 开始支付事务监听, 并且开始支付凭证验证队列.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // 刷新收据信息.
    [self refreshTransactionReceiptDataIfNeed];
    
    // 检查沙盒中没有持久化的交易.
    [self checkUnfinishedTransactionInSandbox];
}

- (void)fetchProductInfoWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers
                                    completion:(BLPaymentFetchProductCompletion)completion {
    if ([self currentDeviceIsJailbroken]) {
        return;
    }
    
    NSCParameterAssert(productIdentifiers);
    if (!productIdentifiers) {
        return;
    }
    
    // 取消之前的请求.
    if (self.currentProductRequest) {
        [self.currentProductRequest cancel];
        self.currentProductRequest = nil;
        self.fetchProductCompletion = nil;
    }
    self.fetchProductCompletion = completion;
    
    if ([SKPaymentQueue canMakePayments]) {
        [self internalFetchProductInfo:productIdentifiers];
    }
    else {
        NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"用户禁止应用内付费购买"}];
        if (completion) {
            completion(nil, error);
            self.fetchProductCompletion = nil;
        }
    }
}

- (void)buyProduct:(SKProduct *)product error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if ([self currentDeviceIsJailbroken]) {
        return;
    }
    NSParameterAssert(product);
    if (!product) {
        NSError *e = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"product 为空"}];
        if (error) {
            *error = e;
        }
        return;
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


#pragma mark - BLPaymentVerifyManagerDelegate

- (void)paymentVerifyManager:(BLPaymentVerifyManager *)paymentVerifyManager paymentTransactionVerifyValid:(NSString *)transactionIdentifier {
    // 此时应该刷新收据数据.
    [self refreshTransactionReceiptDataIfNeed];
    // 收据有效.
    [self finishATransationWithIndentifier:transactionIdentifier];
    NSLog(@"订单验证成功, 订单号: %@", transactionIdentifier);
}

- (void)paymentVerifyManager:(BLPaymentVerifyManager *)paymentVerifyManager paymentTransactionVerifyInvalid:(NSString *)transactionIdentifier {
    // 此时应该刷新收据数据.
    [self refreshTransactionReceiptDataIfNeed];
    // 收据无效.
    [self finishATransationWithIndentifier:transactionIdentifier];
}

- (void)paymentVerifyManagerRequestFailed:(BLPaymentVerifyManager *)paymentVerifyManager {
    // 此时应该刷新收据数据.
    [self refreshTransactionReceiptDataIfNeed];
}


#pragma mark - SKPaymentTransactionObserver

// 购买操作后的回调.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 这里的事务包含之前没有完成的.
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                [self transactionPurchasing:transaction];
                break;
                
            case SKPaymentTransactionStatePurchased:
                [self transactionPurchased:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self transactionFailed:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self transactionRestored:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                [self transactionDeferred:transaction];
                break;
        }
    }
}


#pragma mark - transactionState

// 交易中.
- (void)transactionPurchasing:(SKPaymentTransaction *)transaction {
    NSLog(@"交易中...");
}

// 交易成功.
- (void)transactionPurchased:(SKPaymentTransaction *)transaction {
    NSLog(@"交易成功...");
    // [BLHUDManager showToastWithText:@"付款成功, 开始验证..."];
    NSParameterAssert(transaction);

    // 检查收据存不存在, 如果存在, 直接传给验证队列.
    NSData *transactionReceiptData = [self fetchTransactionReceiptDataInCurrentDevice];
    if (transactionReceiptData.length) {
        [self.verifyManager refreshTransactionReceiptData:transactionReceiptData];
    }
    else {
        // 报告错误
        NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : [self generateErrorStringForTransaction:transaction]}];
         // [BLAssert reportError:error];
    }

    [self pushPaymentTransactionIntoOperationTaskQueueIfNeed:transaction];
}

// 交易失败.
- (void)transactionFailed:(SKPaymentTransaction *)transaction {
    [NSNotificationCenter.defaultCenter postNotificationName:BLPaymentManagerPaymentFailedNotification object:nil];
    if(transaction.error.code != SKErrorPaymentCancelled) {
        // [BLHUDManager showToastWithText:transaction.error.localizedDescription];
        NSLog(@"购买失败");
    }
    else {
        NSLog(@"用户取消交易");
        // [BLHUDManager showToastWithText:@"用户取消交易"];
    }
    
    [self finishATransation:transaction];
}

// 已经购买过该商品.
- (void)transactionRestored:(SKPaymentTransaction *)transaction {
    NSLog(@"已经购买过该商品...");
}

// 交易延期.
- (void)transactionDeferred:(SKPaymentTransaction *)transaction {
    NSLog(@"交易延期...");
}


#pragma mark - SKProductsRequestDelegate

// 查询成功后的回调.
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray<SKProduct *> *products = response.products;
    NSError *error = nil;
    if (!products.count) {
        error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"没有正在出售的商品"}];
    }
    
    self.products = products;
    if (self.fetchProductCompletion) {
        self.fetchProductCompletion(products, error);
    }
}


#pragma mark - Notification

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveClearAllUnfinishedTransiactionNotification) name:BLClearAllUnfinishedTransiactionNotification object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)note {
    // 检查沙盒中没有持久化的交易.
    [self checkUnfinishedTransactionInSandbox];
}

- (void)didReceiveClearAllUnfinishedTransiactionNotification {
    // 未完成的列表.
    NSArray<SKPaymentTransaction *> *transactionsWaitingForVerifing = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in transactionsWaitingForVerifing) {
        [self finishATransation:transaction];
    }
}


#pragma mark - Private

- (void)checkUnfinishedTransactionInSandbox {
    // 未完成的列表.
    NSArray<SKPaymentTransaction *> *transactionsWaitingForVerifing = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in transactionsWaitingForVerifing) {
        // 购买没有交易标识和购买日期的, 是没有成功付款的, 直接 finish 掉.
        if (!transaction.transactionIdentifier || !transaction.transactionDate) {
            [self finishATransation:transaction];
            continue;
        }
        [self pushPaymentTransactionIntoOperationTaskQueueIfNeed:transaction];
    }
    
    [self.verifyManager startPaymentTransactionVerifingIfNeed];
}

- (void)refreshTransactionReceiptDataIfNeed {
    // 检查收据存不存在, 如果存在, 直接传给验证队列.
    NSData *transactionReceiptData = [self fetchTransactionReceiptDataInCurrentDevice];
    if (transactionReceiptData.length) {
        [self.verifyManager refreshTransactionReceiptData:transactionReceiptData];
    }
}

- (NSData *)fetchTransactionReceiptDataInCurrentDevice {
    NSURL *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    return [NSData dataWithContentsOfURL:appStoreReceiptURL];
}

- (NSString *)dumpATransaction:(SKPaymentTransaction *)transaction {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    NSString *dateString = [formatter stringFromDate:transaction.transactionDate];
    NSString *dump = [NSString stringWithFormat:@"productIdentifier: %@, transactionIdentifier: %@, transactionDate: %@", transaction.payment.productIdentifier, transaction.transactionIdentifier, dateString];
    return dump;
}

- (void)finishATransationWithIndentifier:(NSString *)transactionIdentifier {
    // 未完成的列表.
    NSArray<SKPaymentTransaction *> *transactionsWaitingForVerifing = [[SKPaymentQueue defaultQueue] transactions];
    SKPaymentTransaction *targetTransaction = nil;
    for (SKPaymentTransaction *transaction in transactionsWaitingForVerifing) {
        if ([transactionIdentifier isEqualToString:transaction.transactionIdentifier]) {
            targetTransaction = transaction;
            break;
        }
    }
    
    [self finishATransation:targetTransaction];
}

- (void)finishATransation:(SKPaymentTransaction *)transaction {
    NSParameterAssert(transaction);
    if (!transaction) {
        return;
    }
    
    // 不能完成一个正在交易的订单.
    if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
        return;
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

// 压入队列的会触发自动验证请求 ✅.
- (void)pushPaymentTransactionIntoOperationTaskQueueIfNeed:(SKPaymentTransaction *)transaction {
    // 还没有持久化到验证队列里.
    if ([self.verifyManager transactionDidStoreInKeyChainWithTransactionIdentifier:transaction.transactionIdentifier]) {
        NSLog(@"当前交易已经持久化到了 keychain 中");
        return;
    }
    
    BLPaymentTransactionModel *transactionModel = [self generateTransactionModelWithPaymentTransaction:transaction];
    [self.verifyManager appendPaymentTransactionModel:transactionModel];
}

// 获取到对应的收据, 创建需验证模型, 持久化到需验证队列 ✅.
- (BLPaymentTransactionModel *)generateTransactionModelWithPaymentTransaction:(SKPaymentTransaction *)transaction {
    return [[BLPaymentTransactionModel alloc]
            initWithProductIdentifier:transaction.payment.productIdentifier
            transactionIdentifier:transaction.transactionIdentifier
            transactionDate:transaction.transactionDate];
}

// 从Apple查询用户点击购买的产品的信息.
- (void)internalFetchProductInfo:(NSSet<NSString *> *)productIdentifiers {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate = self;
    [request start];
    self.currentProductRequest = request;
}

- (NSString *)generateErrorStringForTransaction:(SKPaymentTransaction *)paymentTransaction {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    NSString *dateString = [formatter stringFromDate:paymentTransaction.transactionDate];
    return [NSString stringWithFormat:@"苹果返回购买成功, 但是却拿不到收据信息的订单, 订单信息为: productIdentifier: %@, transactionIdentifier: %@, transactionDate: %@", paymentTransaction.payment.productIdentifier, paymentTransaction.transactionIdentifier, dateString];
}

@end
