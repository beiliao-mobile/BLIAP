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

#import "BLPaymentTransactionModel.h"
#import "BLWalletCompat.h"

NSUInteger const kBLPaymentTransactionModelVerifyWarningCount = 10; // 最多验证次数，如果超过这个值就报警。
@implementation BLPaymentTransactionModel

- (NSString *)description {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    NSString *dateString = [formatter stringFromDate:self.transactionDate];
    return [NSString stringWithFormat:@"productIdentifier: %@, transactionIdentifier: %@, transactionDate: %@, orderNo:%@, modelVerifyCount:%ld", self.productIdentifier, self.transactionIdentifier, dateString, self.orderNo, self.modelVerifyCount];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _productIdentifier = [aDecoder decodeObjectForKey:@"productIdentifier"];
        _transactionIdentifier = [aDecoder decodeObjectForKey:@"transactionIdentifier"];
        _transactionDate = [aDecoder decodeObjectForKey:@"transactionDate"];
        _orderNo = [aDecoder decodeObjectForKey:@"orderNo"];
        _modelVerifyCount = [aDecoder decodeIntegerForKey:@"modelVerifyCount"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.productIdentifier forKey:@"productIdentifier"];
    [aCoder encodeObject:self.transactionIdentifier forKey:@"transactionIdentifier"];
    [aCoder encodeObject:self.transactionDate forKey:@"transactionDate"];
    [aCoder encodeObject:self.orderNo forKey:@"orderNo"];
    [aCoder encodeInteger:self.modelVerifyCount forKey:@"modelVerifyCount"];
}

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                    transactionIdentifier:(NSString *)transactionIdentifier
                          transactionDate:(NSDate *)transactionDate
                                  orderNo:(NSString *)orderNo {
    NSParameterAssert(productIdentifier);
    NSParameterAssert(transactionIdentifier);
    NSParameterAssert(transactionDate);
    NSParameterAssert(orderNo);
    NSString *errorString = nil;
    if (!productIdentifier.length || !transactionIdentifier.length || !transactionDate || !orderNo.length) {
        errorString = [NSString stringWithFormat:@"致命错误: 初始化贝聊钱包商品交易模型时, productIdentifier: %@, transactionIdentifier: %@, transactionDate: %@, orderNo:%@ 中有数据为空", productIdentifier, transactionIdentifier, [NSString stringWithFormat:@"%f", transactionDate.timeIntervalSince1970], orderNo];
    }
    
    if (errorString) {
        // 报告错误.
        NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : errorString}];
        // [BLAssert reportError:error];
        return nil;
    }
    
    self = [super init];
    if (self) {
        _productIdentifier = productIdentifier;
        _transactionIdentifier = transactionIdentifier;
        _transactionDate = transactionDate;
        _orderNo = orderNo;
        _modelVerifyCount = 0;
    }
    return self;
}

- (void)setModelVerifyCount:(NSUInteger)modelVerifyCount {
    _modelVerifyCount = modelVerifyCount;
    
    if (modelVerifyCount > kBLPaymentTransactionModelVerifyWarningCount) {
        NSString *errorString = [NSString stringWithFormat:@"验证次数超过最大验证次数: %@", self];
        NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : errorString}];
        // 报警.
        // [BLAssert reportError:error];
    }
}

#pragma mark - Private

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[BLPaymentTransactionModel class]]) {
        return NO;
    }
    
    return [self isEqualToModel:((BLPaymentTransactionModel *)object)];
}

- (BOOL)isEqualToModel:(BLPaymentTransactionModel *)object {
    BOOL isTransactionIdentifierMatch = [self.transactionIdentifier isEqualToString:object.transactionIdentifier];
    BOOL isProductIdentifierMatch = [self.productIdentifier isEqualToString:object.productIdentifier];
    BOOL isOrderNoMatch = [self.orderNo isEqualToString:object.orderNo];
    return isTransactionIdentifierMatch && isProductIdentifierMatch & isOrderNoMatch;
}

@end
