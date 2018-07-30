//
//  WKWebView+MYCaptureImage.h
//  MiYaBaoBei
//
//  Created by zhangzhe on 2018/7/26.
//  Copyright © 2018 蜜芽. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
// 给H5 （滚动/不滚动） 截长屏
// 使用的 https://github.com/startry/SwViewCapture.git 翻译成oc
@interface WKWebView (MYCaptureImage)

//- (void)swContentCapture:(void(^)(UIImage * capturedImage))completionHandler;

//  wk 主要用这个
- (void)swContentScrollCapture:(void(^)(UIImage *capturedImage))completionHandler;

@end

NS_ASSUME_NONNULL_END
