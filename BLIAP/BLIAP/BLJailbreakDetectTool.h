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

#import <Foundation/Foundation.h>

@interface BLJailbreakDetectTool : NSObject

/**
 * 检查当前设备是否已经越狱。
 */
+ (BOOL)detectCurrentDeviceIsJailbroken;

@end
