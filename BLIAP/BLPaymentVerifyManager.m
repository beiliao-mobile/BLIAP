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

#import "BLPaymentVerifyManager.h"
#import "BLWalletKeyChainStore.h"
#import "BLPaymentTransactionModel.h"
#import "BLPaymentVerifyTask.h"
#import "BLWalletKeyChainStore.h"
#import "BLWalletCompat.h"

@interface BLPaymentVerifyManager()<BLPaymentVerifyTaskDelegate>

/**
 * 操作队列.
 */
@property(nonatomic, strong) NSMutableArray<BLPaymentVerifyTask *> *operationTaskQueue; // 最大并发验证数量为 1.

/**
 * 收据(开始验证之前, 必须保证收据不为空).
 */
@property(nonatomic, strong, nullable) NSData *transactionReceiptData;

/**
 * keychainStore.
 */
@property(nonatomic, strong, nonnull) BLWalletKeyChainStore *keychainStore;

/**
 * 当前正在验证的 task.
 */
@property(nonatomic, strong) BLPaymentVerifyTask *currentVerifingTask;

/**
 * userID.
 */
@property(nonatomic, copy) NSString *userid;

@end

NSString *const kBLPaymentVerifyManagerKeychainStoreServiceKey = @"com.ibeiliao.payment.keychain.store.service.key.com";
@implementation BLPaymentVerifyManager

- (instancetype)init {
    NSAssert(NO, @"请使用指定的方法初始化");
    return [self initWithUserID:[NSString new]];
}

- (instancetype)initWithUserID:(NSString *)userid {
    NSParameterAssert(userid);
    if (!userid) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _userid = userid;
        _currentVerifingTask = nil;
        _keychainStore = [BLWalletKeyChainStore keyChainStoreWithService:kBLPaymentVerifyManagerKeychainStoreServiceKey];
    }
    return self;
}


#pragma mark - Public

- (void)startPaymentTransactionVerifingIfNeed {
    [self internalStartPaymentTransactionVerifing];
}

- (void)refreshTransactionReceiptData:(NSData *)transactionReceiptData {
    NSParameterAssert(transactionReceiptData.length);
    if (!transactionReceiptData.length) {
        return;
    }
    
    self.transactionReceiptData = transactionReceiptData;
}

- (void)appendPaymentTransactionModel:(BLPaymentTransactionModel *)transactionModel {
    NSAssert([NSThread isMainThread], @"不能再子线程进行当前操作");
    NSAssert(transactionModel, @"transactionModel 为空");
    if (!transactionModel) {
        return;
    }
    
    [self internalAppendPaymentTransactionModel:transactionModel];
}

- (BOOL)transactionDidStoreInKeyChainWithTransactionIdentifier:(NSString *)transactionIdentifier {
    NSParameterAssert(transactionIdentifier);
    if (!transactionIdentifier.length) {
        return NO;
    }
    
    NSArray<BLPaymentTransactionModel *> *models = [self.keychainStore bl_fetchAllPaymentTransactionModelsForUser:self.userid error:nil];
    if (!models.count) {
        return NO;
    }
    
    for (BLPaymentTransactionModel *model in models) {
        if ([model.transactionIdentifier isEqualToString:transactionIdentifier]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)didNeedVerifyQueueClearedForCurrentUser {
    // 所有还未得到验证的交易(持久化的).
    NSArray<BLPaymentTransactionModel *> *transationModels = [self.keychainStore bl_fetchAllPaymentTransactionModelsSortedArrayUsingComparator:^NSComparisonResult(BLPaymentTransactionModel * obj1, BLPaymentTransactionModel *obj2) {
        
        return [obj1.transactionDate compare:obj2.transactionDate] == NSOrderedAscending; // 日期升序排序.
        
    } forUser:self.userid error:nil];
    return transationModels.count;
}

- (void)cancelAllTasks {
    if (self.currentVerifingTask) {
        [self.currentVerifingTask cancel];
    }
    
    self.operationTaskQueue = nil;
}

#pragma mark - BLPaymentVerifyTaskDelegate

- (void)paymentVerifyTaskRequestDidStart:(BLPaymentVerifyTask *)task {
    if (![self inspectTask:task isCurrentVerifyTask:self.currentVerifingTask]) {
        [self cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed];
    }
}

- (void)paymentVerifyTaskDidReceiveResponseReceiptValid:(BLPaymentVerifyTask *)task {
    if (![self inspectTask:task isCurrentVerifyTask:self.currentVerifingTask]) {
        [self cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed];
        return;
    }
    
    // 通知代理将改 transactionIdentifier 的 transaction finish 掉.
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyManager:paymentTransactionVerifyValid:)]) {
        [self.delegate paymentVerifyManager:self paymentTransactionVerifyValid:task.transactionModel.transactionIdentifier];
    }
    
    [self removeFinishedTask:task];
    self.currentVerifingTask = nil;
    
    // 执行下一条任务.
    [self startNextTaskIfNeed];
}

- (void)paymentVerifyTaskDidReceiveResponseReceiptInvalid:(BLPaymentVerifyTask *)task {
    if (![self inspectTask:task isCurrentVerifyTask:self.currentVerifingTask]) {
        [self cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed];
        return;
    }
    
    // 通知代理将改 transactionIdentifier 的 transaction finish 掉.
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyManager:paymentTransactionVerifyInvalid:)]) {
        [self.delegate paymentVerifyManager:self paymentTransactionVerifyInvalid:task.transactionModel.transactionIdentifier];
    }
    
    [self removeFinishedTask:task];
    self.currentVerifingTask = nil;
    
    // 执行下一条任务.
    [self startNextTaskIfNeed];
}

- (void)paymentVerifyTaskRequestFailed:(BLPaymentVerifyTask *)task {
    if (![self inspectTask:task isCurrentVerifyTask:self.currentVerifingTask]) {
        [self cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed];
        return;
    }
    
    // 通知代理, 此时应该刷新收据数据.
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyManagerRequestFailed:)]) {
        [self.delegate paymentVerifyManagerRequestFailed:self];
    }
    
    // 给已经验证过一次的失败的交易打上等待重新验证的标识.
    [self.keychainStore bl_updatePaymentTransactionModelStateWithTransactionIdentifier:task.transactionModel.transactionIdentifier modelVerifyCount:task.transactionModel.modelVerifyCount + 1  forUser:self.userid];
    self.currentVerifingTask = nil;
    
    // 重新执行当前任务.
    [self startNextTaskIfNeed];
}


#pragma mark - Private

- (BOOL)inspectTask:(BLPaymentVerifyTask *)task isCurrentVerifyTask:(BLPaymentVerifyTask *)currentVerifyTask {
    NSAssert([NSThread isMainThread], @"不能再子线程进行当前操作");
    NSAssert([currentVerifyTask isEqual:task], @"致命错误 😢, 当前的响应结果不是正在进行验证的收据的响应");
    NSAssert([self.operationTaskQueue containsObject:task], @"致命错误 😢, 当前的 task 已经不在 task 队列中");
    return [currentVerifyTask isEqual:task];
}

- (void)cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed {
    [self internalStartPaymentTransactionVerifing];
}

- (void)removeFinishedTask:(BLPaymentVerifyTask *)task {
    // 验证有结果, 将该条凭证数据从 keychain 里面删除掉.
    [self.keychainStore bl_deletePaymentTransactionModelWithTransactionIdentifier:task.transactionModel.transactionIdentifier forUser:self.userid];
    // 将当前任务从队列中移除掉.
    [self.operationTaskQueue removeObject:task];
}

- (void)startNextTaskIfNeed {
    // 直接重置的原因是, 防止当前是在重试验证, 此时新进来交易.
    // 可能出现新的交易一直得不到验证, 一直在重复验证那些已经验证过, 但是失败的交易.
    [self internalStartPaymentTransactionVerifing];
}

- (void)internalAppendPaymentTransactionModel:(BLPaymentTransactionModel *)transactionModel {
    // 首先持久化到 keychain.
    [self.keychainStore bl_savePaymentTransactionModels:@[transactionModel] forUser:self.userid];
    
    // 如果有在执行的任务, 不打断当前的验证.
    // 等待当前任务执行完就会将当前这个模型推入到验证队列.
    if (self.currentVerifingTask) {
        return;
    }
    
    // 如果没有在执行的任务就直接开始当前验证.
    [self cancelAllTaskAndResetAllModelsThenStartFirstTaskIfNeed];
}


#pragma mark - Setup

- (void)internalStartPaymentTransactionVerifing {
    [self resetAllIfNeed];
    
    // 开始第一个任务.
    [self startFirstTaskInOperationQueueIfNeed];
}

- (void)startFirstTaskInOperationQueueIfNeed {
    if (!self.operationTaskQueue.count) {
        return;
    }
    
    // 步长设定.
    // 只要是已经和后台验证过并且失败过的交易, 两次请求之间的时间间隔是失败的次数 * BLPaymentVerifyUploadReceiptDataIntervalDelta.
    __weak typeof(self) wself = self;
    self.currentVerifingTask = self.operationTaskQueue.firstObject;
    if (self.currentVerifingTask.transactionModel.modelVerifyCount > 0) { // 说明是重新验证.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.currentVerifingTask.transactionModel.modelVerifyCount * BLPaymentVerifyUploadReceiptDataIntervalDelta * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            __strong typeof(wself) sself = wself;
            if (!sself) return;
            [self.currentVerifingTask start];
            
        });
    }
    else {
        [self.currentVerifingTask start];
    }
}

- (void)resetAllIfNeed {
    // 取消当前 task.
    if (self.currentVerifingTask) {
        [self.currentVerifingTask cancel];
    }
    
    // 重置任务队列.
    [self resetOperationTaskQueueIfNeed];
}

- (void)resetOperationTaskQueueIfNeed {
    if (!self.transactionReceiptData.length) {
        NSLog(@"收据为空, 先传收据进来, 再开始队列");
        return;
    }
    
    self.operationTaskQueue = nil;
    
    NSError *error = nil;
    // 所有还未得到验证的交易(持久化的).
    NSArray<BLPaymentTransactionModel *> *transationModels = [self.keychainStore bl_fetchAllPaymentTransactionModelsForUser:self.userid error:&error];
    
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    if (!transationModels.count) {
        return;
    }
    
    // 动态规划当前应该验证哪一笔订单.
    NSArray<BLPaymentTransactionModel *> *transationModelsVerifyNow = [self dynamicPlanNeedVerifyModelsWithAllModels:transationModels];
    
    NSParameterAssert(self.transactionReceiptData.length);
    NSMutableArray<BLPaymentVerifyTask *> *tasksM = [NSMutableArray arrayWithCapacity:transationModelsVerifyNow.count];
    for (BLPaymentTransactionModel *model in transationModelsVerifyNow) {
        BLPaymentVerifyTask *task = [[BLPaymentVerifyTask alloc] initWithPaymentTransactionModel:model transactionReceiptData:self.transactionReceiptData];
        task.delegate = self;
        [tasksM addObject:task];
    }
    self.operationTaskQueue = tasksM;
}

// 动态规划当前应该验证哪一笔订单.
- (NSArray<BLPaymentTransactionModel *> *)dynamicPlanNeedVerifyModelsWithAllModels:(NSArray<BLPaymentTransactionModel *> *) allTransationModels {
    // 防止出现: 第一个失败的订单一直在验证, 排队的订单得不到验证.
    NSMutableArray<BLPaymentTransactionModel *> *transactionModelsNeverVerify = [NSMutableArray array];
    NSMutableArray<BLPaymentTransactionModel *> *transactionModelsRetry = [NSMutableArray array];
    for (BLPaymentTransactionModel *model in allTransationModels) {
        if (model.modelVerifyCount == 0) {
            [transactionModelsNeverVerify addObject:model];
        }
        else {
            [transactionModelsRetry addObject:model];
        }
    }
    
    // 从未验证过的订单, 优先验证.
    if (transactionModelsNeverVerify.count) {
        return transactionModelsNeverVerify.copy;
    }
    
    // 验证次数少的排前面.
    [transactionModelsRetry sortUsingComparator:^NSComparisonResult(BLPaymentTransactionModel * obj1, BLPaymentTransactionModel * obj2) {
       
        return obj1.modelVerifyCount < obj2.modelVerifyCount;
        
    }];
    
    return transactionModelsRetry.copy;
}

@end
