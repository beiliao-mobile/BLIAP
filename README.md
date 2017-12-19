# BLIAP

处理了 IAP 九大坑, 并且封装了收据验证队列, 最大限度保证 IAP 安全的示例代码.

## 1.模块划分如下:

![](http://upload-images.jianshu.io/upload_images/2122663-f53a3ddd98eda000.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 2.运行流程如下:

![](http://upload-images.jianshu.io/upload_images/2122663-82548451af3eaa95.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 3.使用时注意.

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
