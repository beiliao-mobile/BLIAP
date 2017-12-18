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
#import <NSData+MD5Digest.h>

@interface BLPaymentVerifyTask()<UIAlertViewDelegate>

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
    
    NSString *receipts = [self.transactionReceiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    if (!receipts.length) {
        NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"验证收据为空 crtf: %@", receipts]}];
        // [BLAssert reportError:error];
    }
    
    // 如果有订单号和 md5 值, 并且 md5 值没有变动, 开始验证.
    NSString *md5 = [NSData MD5HexDigest:[receipts dataUsingEncoding:NSUTF8StringEncoding]];
    BOOL needStartVerify = self.transactionModel.orderNo.length && self.transactionModel.md5 && [self.transactionModel.md5 isEqualToString:md5];
    self.taskState = BLPaymentVerifyTaskStateWaitingForServersResponse;
    if (needStartVerify) {
        NSLog(@"开始上传收据验证");
        [self sendUploadCertificateRequest];
    }
    else {
        NSLog(@"开始创建订单");
        [self sendCreateOrderRequestWithProductIdentifier:self.transactionModel.productIdentifier md5:md5];
    }
}

- (void)cancel {
    self.taskState = BLPaymentVerifyTaskStateCancel;
    
    // 执行取消请求.
}


#pragma mark - Request

- (void)sendCreateOrderRequestWithProductIdentifier:(NSString *)productIdentifier md5:(NSString *)md5 {
    // 发送创建订单请求.
}

- (void)sendUploadCertificateRequest {
    // 发送上传凭证进行验证请求.
    NSString *receipts = [self.transactionReceiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *md5 = [NSData MD5HexDigest:[receipts dataUsingEncoding:NSUTF8StringEncoding]];
}


#pragma mark - Request Result Handle

- (void)handleVerifingTransactionValid {
    NSLog(@"订单验证成功, valid");
    [self sendNotificationWithName:BLPaymentVerifyTaskDidReceiveResponseReceiptValidNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskDidReceiveResponseReceiptValid:)]) {
        [self.delegate paymentVerifyTaskDidReceiveResponseReceiptValid:self];
    }
}

- (void)handleVerifingTransactionInvalidWithErrorMessage:(NSString *)errorMsg {
    NSLog(@"订单验证成功, invalid");
    [self sendNotificationWithName:BLPaymentVerifyTaskDidReceiveResponseReceiptInvalidNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskDidReceiveResponseReceiptInvalid:)]) {
        [self.delegate paymentVerifyTaskDidReceiveResponseReceiptInvalid:self];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorMsg message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)handleUploadCertificateRequestFailed {
    NSLog(@"订单验证失败");
    [self sendNotificationWithName:BLPaymentVerifyTaskUploadCertificateRequestFailedNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskUploadCertificateRequestFailed:)]) {
        [self.delegate paymentVerifyTaskUploadCertificateRequestFailed:self];
    }
}

- (void)handleCreateOrderSuccessedWithOrderNo:(NSString *)orderNo
                               priceTagString:(NSString *)priceTagString
                                          md5:(NSString *)md5 {
    NSLog(@"创建订单成功");
    [self sendNotificationWithName:BLPaymentVerifyTaskCreateOrderDidSuccessedNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskDidReceiveCreateOrderResponse:orderNo:priceTagString:md5:)]) {
        [self.delegate paymentVerifyTaskDidReceiveCreateOrderResponse:self orderNo:orderNo priceTagString:priceTagString md5:md5];
    }
}

- (void)handleCreateOrderFailed {
    NSLog(@"创建订单失败");
    [self sendNotificationWithName:BLPaymentVerifyTaskCreateOrderRequestFailedNotification];
    if (self.delegate && [self.delegate respondsToSelector:@selector(paymentVerifyTaskCreateOrderRequestFailed:)]) {
        [self.delegate paymentVerifyTaskCreateOrderRequestFailed:self];
    }
}


#pragma mark - Private

- (void)reportErrorWithErrorString:(NSString *)string {
    NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : string}];
    // [BLAssert reportError:error];
}

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
    return isTransactionIdentifierMatch && isProductIdentifierMatch;
}

- (void)sendNotificationWithName:(NSString *)noteName {
    [[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
}

@end
