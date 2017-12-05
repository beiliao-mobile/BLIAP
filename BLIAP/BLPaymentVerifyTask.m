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

#import "BLPaymentVerifyTask.h"
#import "BLPaymentTransactionModel.h"
#import "BLWalletCompat.h"

@interface BLPaymentVerifyTask()

/**
 * 交易凭证验证模型.
 */
@property(nonatomic, strong, nonnull) BLPaymentTransactionModel *transactionModel;

/**
 * task 状态.
 */
@property(nonatomic, assign) BLPaymentVerifyTaskState taskState;

/**
 * 收据.
 */
@property(nonatomic, strong, nonnull) NSData *transactionReceiptData;

@end

@implementation BLPaymentVerifyTask

- (instancetype)init {
    NSAssert(NO, @"使用指定的初始化接口来初始化当前类");
    return [self initWithPaymentTransactionModel:[BLPaymentTransactionModel new] transactionReceiptData:[NSData new]];
}

- (instancetype)initWithPaymentTransactionModel:(BLPaymentTransactionModel *)paymentTransactionModel transactionReceiptData:(nonnull NSData *)transactionReceiptData {
    NSParameterAssert(paymentTransactionModel);
    NSParameterAssert(transactionReceiptData);
    if (!paymentTransactionModel || !transactionReceiptData.length) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _transactionModel = paymentTransactionModel;
        _taskState = BLPaymentVerifyTaskStateDefault;
        _transactionReceiptData = transactionReceiptData;
    }
    return self;
}

- (void)start {
    if (self.taskState == BLPaymentVerifyTaskStateCancel) {
        NSLog(@"尝试调起一个被取消的 task 😢");
        return;
    }
    
    // 发送上传凭证进行验证请求.
    
}

- (void)cancel {
    self.taskState = BLPaymentVerifyTaskStateCancel;
    
    // 执行取消请求.
}


#pragma mark - Request Result Handle

- (void)handleStartSendRequest {
    [self sendNotificationWithName:BLPaymentVerifyTaskStartNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskRequestDidStart:)]) {
        [self.delegate paymentVerifyTaskRequestDidStart:self];
    }
}

- (void)handleVerifingTransactionValid {
    [self sendNotificationWithName:BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskDidReceiveResponseReceiptValid:)]) {
        [self.delegate paymentVerifyTaskDidReceiveResponseReceiptValid:self];
    }
}

- (void)handleVerifingTransactionInvalid {
    [self sendNotificationWithName:BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskDidReceiveResponseReceiptInvalid:)]) {
        [self.delegate paymentVerifyTaskDidReceiveResponseReceiptInvalid:self];
    }
}

- (void)handleRequestFailed {
    [self sendNotificationWithName:BLPaymentVerifyTaskRequestFailedNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskRequestFailed:)]) {
        [self.delegate paymentVerifyTaskRequestFailed:self];
    }
}


#pragma mark - Private

- (NSString *)description {
    NSString *taskState = nil;
    switch (self.taskState) {
        case BLPaymentVerifyTaskStateDefault:
            taskState = @"BLPaymentVerifyTaskStateDefault";
            break;
        case BLPaymentVerifyTaskStateWaitingForServersResponse:
            taskState = @"BLPaymentVerifyTaskStateWaitingForServersResponse";
            break;
        case BLPaymentVerifyTaskStateFinished:
            taskState = @"BLPaymentVerifyTaskStateFinished";
            break;
        case BLPaymentVerifyTaskStateCancel:
            taskState = @"BLPaymentVerifyTaskStateCancel";
            break;
    }
    return [NSString stringWithFormat:@"delegate: %@, transactionModel: %@, taskState: %@", self.delegate, self.transactionModel, taskState];
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[BLPaymentVerifyTask class]]) {
        return NO;
    }
    
    return [self isEqualToTask:((BLPaymentVerifyTask *)object)];
}

- (BOOL)isEqualToTask:(BLPaymentVerifyTask *)object {
    BOOL isTransactionIdentifierMatch = [self.transactionModel.transactionIdentifier isEqualToString:object.transactionModel.transactionIdentifier];
    BOOL isProductIdentifierMatch = [self.transactionModel.productIdentifier isEqualToString:object.transactionModel.productIdentifier];
    BOOL isOrderNoMatch = [self.transactionModel.orderNo isEqualToString:object.transactionModel.orderNo];
    return isTransactionIdentifierMatch && isProductIdentifierMatch && isOrderNoMatch;
}

- (void)sendNotificationWithName:(NSString *)noteName {
    [[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
}

@end
