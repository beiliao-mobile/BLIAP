//
//  BLWalletInjecting.h
//  beiliao
//
//  Created by NewPan on 2017/12/7.
//  Copyright © 2017年 ibeiliao.com. All rights reserved.
//

#import <libextobjc/EXTConcreteProtocol.h>

@protocol BLWalletInjecting <NSObject>

@optional

@property (nonatomic) NSSet<NSString *> *productIdentifiers;

@end
