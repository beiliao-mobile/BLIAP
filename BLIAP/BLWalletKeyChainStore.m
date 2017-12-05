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

#import "BLWalletKeyChainStore.h"
#import "BLPaymentTransactionModel.h"
#import <pthread.h>
#import "BLWalletCompat.h"

@interface BLWalletKeyChainStore()

@property (nonatomic) pthread_mutex_t lock;

@end

static NSString *const kBLWalletKeyChainStore = @"com.test.wallet.keychain.store.www";
@implementation BLWalletKeyChainStore

+ (UICKeyChainStore *)keyChainStoreWithService:(NSString *)service {
    return [super keyChainStoreWithService:service];
}

- (instancetype)initWithService:(NSString *)service {
    BLWalletKeyChainStore *store = [super initWithService:service];
    pthread_mutex_init(&(_lock), NULL);
    return store;
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

- (void)bl_savePaymentTransactionModels:(NSArray<BLPaymentTransactionModel *> *)models forUser:(nonnull NSString *)userid {
    NSParameterAssert(userid);
    if (!models.count || !userid.length) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    // 将 models 归档.
    NSMutableSet<NSData *> *modelsDataSetM = [NSMutableSet setWithArray:[self internalEncodeModels:models]];
    
    //  与已有的数据组合存储.
    NSMutableArray<BLPaymentTransactionModel *> *modelsExisted = [self bl_fetchAllPaymentTransactionModelsForUser:userid error:nil].mutableCopy;
    if (modelsExisted.count) {
        // 检查一下 keychain 中是否已经存在当前 model.
        for (BLPaymentTransactionModel *modelExisted in modelsExisted) {
            for (BLPaymentTransactionModel *model in models) {
                if ([modelExisted isEqual:model]) {
                    [modelsExisted removeObject:modelExisted];
                    NSLog(@"keychain 中已经有: %@, 不用再存一遍.", model);
                }
            }
        }
        
        if (modelsExisted.count) {
            NSMutableArray<NSData *> *modelsExistedDataM = [self internalEncodeModels:modelsExisted];
            [modelsDataSetM addObjectsFromArray:modelsExistedDataM];
        }
    }
    
    // 存入 keychain.
    [self internalSaveModelsData:modelsDataSetM.copy forUser:userid];
    pthread_mutex_unlock(&_lock);
    
    // 存储结果可靠性检查.
    [self internalCheckModelsSaveResult:models userid:userid];
}

- (BOOL)bl_deletePaymentTransactionModelWithTransactionIdentifier:(NSString *)transactionIdentifier forUser:(nonnull NSString *)userid {
    if (!transactionIdentifier || !userid) {
        return NO;
    }
    
    NSMutableArray<BLPaymentTransactionModel *> * modelsM = [self bl_fetchAllPaymentTransactionModelsForUser:userid error:nil].mutableCopy;
    if (!modelsM.count) {
        return NO;
    }
    
    __block NSInteger index = -100;
    [modelsM enumerateObjectsUsingBlock:^(BLPaymentTransactionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.transactionIdentifier isEqualToString:transactionIdentifier]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index < 0) {
        NSLog(@"%@", [NSString stringWithFormat:@"keychain 不存在 transactionIdentifier 为: %@ 的数据.", transactionIdentifier]);
        return NO;
    }
    
    pthread_mutex_lock(&_lock);
    [modelsM removeObjectAtIndex:index];
    
    // 将 models 归档.
    NSMutableSet<NSData *> *modelsDataSetM = [NSMutableSet setWithArray:[self internalEncodeModels:modelsM]];
    
    // 存入 keychain.
    [self internalSaveModelsData:modelsDataSetM.copy forUser:userid];
    
    pthread_mutex_unlock(&_lock);
    
    return YES;
}

- (void)bl_deleteAllPaymentTransactionModelsIfNeedForUser:(NSString *)userid {
    NSParameterAssert(userid);
    if (!userid) {
        return;
    }

    pthread_mutex_lock(&_lock);
    NSData *dictData = [self dataForKey:kBLWalletKeyChainStore];
    NSMutableDictionary *dictM;
    if (dictData.length) {
        dictM = [NSKeyedUnarchiver unarchiveObjectWithData:dictData];
    }
    if ([dictM.allKeys containsObject:userid]) {
        [dictM removeObjectForKey:userid];
    }
    
    NSData *data;
    if (dictM.allKeys.count) {
        data = [NSKeyedArchiver archivedDataWithRootObject:dictM];
    }
    
    // 先删除, 后存储.
    [self removeItemForKey:kBLWalletKeyChainStore];
    if (data) {
        [self setData:data forKey:kBLWalletKeyChainStore];
    }
    pthread_mutex_unlock(&_lock);
}

- (NSArray<BLPaymentTransactionModel *> *)bl_fetchAllPaymentTransactionModelsForUser:(NSString *)userid error:(NSError *__autoreleasing  _Nullable *)error {
    NSParameterAssert(userid);
    if (!userid) {
       NSError *e = [NSError errorWithDomain:kBLWalletKeyChainStore code:0 userInfo:@{NSLocalizedDescriptionKey : @"userid 为空"}];
        if (error) {
            *error = e;
        }
        return nil;
    }
    
    pthread_mutex_lock(&_lock);
    NSData *data = [self dataForKey:kBLWalletKeyChainStore error:error];
    if (!data.length) {
        NSError *e = [NSError errorWithDomain:kBLWalletKeyChainStore code:0 userInfo:@{NSLocalizedDescriptionKey : @"keychain 中数据为空"}];
        if (error) {
            *error = e;
        }
        return nil;
    }
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (!dict.allKeys.count) {
        NSError *e = [NSError errorWithDomain:kBLWalletKeyChainStore code:0 userInfo:@{NSLocalizedDescriptionKey : @"keychain 中数据为空"}];
        if (error) {
            *error = e;
        }
        return nil;
    }
    
    NSMutableArray<NSData *> *modelsData = nil;
    if (![dict.allKeys containsObject:userid]) {
        NSError *e = [NSError errorWithDomain:kBLWalletKeyChainStore code:0 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"keychain 中没有 userID 为 %@ 的数据", userid]}];
        if (error) {
            *error = e;
        }
        return nil;
    }
    modelsData = [NSKeyedUnarchiver unarchiveObjectWithData:[dict valueForKey:userid]];
    
    NSMutableArray<BLPaymentTransactionModel *> *arrM = [NSMutableArray arrayWithCapacity:modelsData.count];
    for (NSData *data in modelsData) {
        NSParameterAssert([data isKindOfClass:[NSData class]]);
        BLPaymentTransactionModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (model) {
            [arrM addObject:model];
        }
    }
    pthread_mutex_lock(&_lock);
    
    return arrM.copy;
}

- (NSArray<BLPaymentTransactionModel *> *)bl_fetchAllPaymentTransactionModelsSortedArrayUsingComparator:(NSComparator)cmptr forUser:(nonnull NSString *)userid error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSArray<BLPaymentTransactionModel *> *models = [self bl_fetchAllPaymentTransactionModelsForUser:userid error:error];
    if (!models.count) {
        return nil;
    }
    
    if (models.count == 1 || !cmptr) {
        return models;
    }
    
    if (cmptr) {
        return [models sortedArrayUsingComparator:cmptr];
    }
    
    return models;
}

- (void)bl_updatePaymentTransactionModelStateWithTransactionIdentifier:(NSString *)transactionIdentifier modelVerifyCount:(NSUInteger)modelVerifyCount forUser:(nonnull NSString *)userid {
    if (!transactionIdentifier || !userid) {
        return;
    }
    
    NSMutableArray<BLPaymentTransactionModel *> * modelsM = [self bl_fetchAllPaymentTransactionModelsForUser:userid error:nil].mutableCopy;
    if (!modelsM.count) {
        return;
    }
    
    __block NSInteger index = -100;
    [modelsM enumerateObjectsUsingBlock:^(BLPaymentTransactionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.transactionIdentifier isEqualToString:transactionIdentifier]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index < 0) {
        NSLog(@"%@", [NSString stringWithFormat:@"keychain 不存在 transactionIdentifier 为: %@ 的数据.", transactionIdentifier]);
        return;
    }
    
    pthread_mutex_lock(&_lock);
    modelsM[index].modelVerifyCount = modelVerifyCount;
    
    // 将 models 归档.
    NSMutableSet<NSData *> *modelsDataSetM = [NSMutableSet setWithArray:[self internalEncodeModels:modelsM]];
    
    // 存入 keychain.
    [self internalSaveModelsData:modelsDataSetM.copy forUser:userid];
    
    pthread_mutex_unlock(&_lock);
}


#pragma mark - Private

- (NSMutableArray<NSData *> *)internalEncodeModels:(NSArray<BLPaymentTransactionModel *> *)models {
    NSMutableArray *modelsDataM = [NSMutableArray array];
    for (BLPaymentTransactionModel *model in models) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
        NSParameterAssert(data);
        if (data) {
            [modelsDataM addObject:data];
        }
    }
    return modelsDataM;
}

- (void)internalSaveModelsData:(NSSet<NSData *> *)modelsData forUser:(NSString *)userid {
    NSData *setData = [NSKeyedArchiver archivedDataWithRootObject:modelsData];
    NSData *dictData = [self dataForKey:kBLWalletKeyChainStore];
    NSMutableDictionary *dictM;
    if (dictData) {
        dictM = [NSKeyedUnarchiver unarchiveObjectWithData:dictData];
    }
    if (!dictM) {
        dictM = [NSMutableDictionary dictionary];
    }
    
    [dictM setObject:setData forKey:userid];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictM];
    
    // 先删除, 后存储.
    [self removeItemForKey:kBLWalletKeyChainStore];
    if (dictM.allKeys.count) {
        [self setData:data forKey:kBLWalletKeyChainStore];
    }
}

// 存储结果可靠性检查.
- (void)internalCheckModelsSaveResult:(NSArray<BLPaymentTransactionModel *> *)models userid:(NSString *)userid {
    NSArray<BLPaymentTransactionModel *> *modelsExisted = [self bl_fetchAllPaymentTransactionModelsForUser:userid error:nil];
    for (BLPaymentTransactionModel *model in models) {
        BOOL contained = NO;
        for (BLPaymentTransactionModel *existedModel in modelsExisted) {
            if ([existedModel isEqual:model]) {
                contained = YES;
            }
        }
        if (!contained) {
            // 报告错误.
            NSError *error = [NSError errorWithDomain:BLWalletErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"存储模型到 keychain 存完以后, keychain 里没有 %@", model]}];
            // [BLAssert reportError:error];
        }
    }
}

@end
