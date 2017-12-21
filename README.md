# BLIAP

处理了 IAP 九大坑, 并且封装了收据验证队列, 最大限度保证 IAP 安全的示例代码.

## 模块划分如下:

![](http://upload-images.jianshu.io/upload_images/2122663-f53a3ddd98eda000.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 运行流程如下:

![](http://upload-images.jianshu.io/upload_images/2122663-82548451af3eaa95.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 使用时注意.

使用时, 可以直接将示例代码拖进项目. 

注意, 示例代码并没有实现在自己的服务器上创建订单和去自己服务器上验证的相关逻辑, 使用时需要在 `BLPaymentVerifyTask` 类中填充以下两个方法.

```objc
- (void)sendCreateOrderRequestWithProductIdentifier:(NSString *)productIdentifier md5:(NSString *)md5; 
- (void)sendUploadCertificateRequest;
```

并在请求结果中将请求结果转为验证支付成功 / 失败 / 错误这三种情况, 并调用以下方法驱动整个验证流程.

```objc
- (void)handleVerifingTransactionValid;
- (void)handleVerifingTransactionInvalidWithErrorMessage:(NSString *)errorMsg;
- (void)handleUploadCertificateRequestFailed;
- (void)handleCreateOrderSuccessedWithOrderNo:(NSString *)orderNo
                               priceTagString:(NSString *)priceTagString
                                          md5:(NSString *)md5;
- (void)handleCreateOrderFailed;
```

关于示例代码的使用请查看 `BLPaymentManager` 这个类的头文件.

## 实现思路

这个示例代码的实现思路请参考我的文章:

> 第一篇：[[iOS]贝聊 IAP 实战之满地是坑](http://www.jianshu.com/p/07b5ec193353)，这一篇是支付基础知识的讲解，主要会详细介绍 IAP，同时也会对比支付宝和微信支付，从而引出 IAP 的坑和注意点。
>
> 第二篇：[[iOS]贝聊 IAP 实战之见坑填坑](http://www.jianshu.com/p/8e5bf711f9f0)，这一篇是高潮性的一篇，主要针对第一篇文章中分析出的 IAP 的问题进行具体解决。
>
> 第三篇：[[iOS]贝聊 IAP 实战之订单绑定](http://www.jianshu.com/p/847838cde48b)，这一篇是关键性的一篇，主要讲述作者探索将自己服务器生成的订单号绑定到 IAP 上的过程。
