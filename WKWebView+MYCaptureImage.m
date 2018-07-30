//
//  WKWebView+MYCaptureImage.m
//  MiYaBaoBei
//
//  Created by zhangzhe on 2018/7/26.
//  Copyright © 2018 蜜芽. All rights reserved.
//

#import "WKWebView+MYCaptureImage.h"

// Returns YES if |view| or any view it contains is a WKWebView.
BOOL ViewHierarchyContainsWKWebView(UIView* view) {
    if ([view isKindOfClass:[WKWebView class]])
        return YES;
    for (UIView* subview in view.subviews) {
        if (ViewHierarchyContainsWKWebView(subview))
            return YES;
    }
    return NO;
}

static NSString * SwViewCaptureKey_IsCapturing = @"SwViewCapture_AssoKey_isCapturing";

@implementation WKWebView (MYCaptureImage)

- (void)setIsCapturing:(BOOL)isCapturing
{
    objc_setAssociatedObject(self, &SwViewCaptureKey_IsCapturing, @(isCapturing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isCapturing
{
    NSNumber *num  = objc_getAssociatedObject(self, &SwViewCaptureKey_IsCapturing);
    return num.boolValue;
}

- (void)swContentCapture:(void(^)(UIImage * capturedImage))completionHandler
{
    self.isCapturing = true;
    CGPoint offset = self.scrollView.contentOffset;
    // Put a fake Cover of View
    UIView  *snapShotView = [self snapshotViewAfterScreenUpdates:YES];
//    let snapShotView = self.snapshotView(afterScreenUpdates: true)
    snapShotView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, snapShotView.frame.size.width, snapShotView.frame.size.height);
//    [self.superview addSubview:snapShotView];
    if (self.frame.size.height < self.scrollView.contentSize.height) {
        self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentSize.height - self.frame.size.height);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView.contentOffset = CGPointZero;
        __weak __typeof(self)weakSelf = self;
        [self swContentCaptureWithoutOffset:^(UIImage *capturedImage) {
            
            __strong typeof(self) StrongSelf = weakSelf;
            
            StrongSelf.scrollView.contentOffset = offset;
//            [snapShotView removeFromSuperview];
            StrongSelf.isCapturing = false;
            completionHandler(capturedImage);
        }];
        
    });
}

- (void)swContentCaptureWithoutOffset:(void(^)(UIImage * capturedImage))completionHandler
{
    UIView *containerView  = [[UIView alloc] initWithFrame:self.bounds];
    
    CGRect bakFrame     = self.frame;
    UIView  *bakSuperView = self.superview;
//    let bakIndex     = self.superview?.subviews.index(of: self)
    NSInteger bakIndex = [self.superview.subviews indexOfObject:self];
    
    // remove WebView from superview & put container view
    [self removeFromSuperview];
//    self.removeFromSuperview()
//    containerView.addSubview(self)
    [containerView addSubview:self];
    
    CGSize totalSize = self.scrollView.contentSize;
//    let page       = floorf(Float( totalSize.height / containerView.bounds.height))
    CGFloat page = floorf(totalSize.height/containerView.bounds.size.height);
    
//    self.frame = CGRect(x: 0, y: 0, width: containerView.bounds.size.width, height: self.scrollView.contentSize.height)
    self.frame = CGRectMake(0, 0, containerView.bounds.size.width, self.scrollView.contentSize.height);
    
//    UIGraphicsBeginImageContextWithOptions(totalSize, false, UIScreen.main.scale)
    UIGraphicsBeginImageContextWithOptions(totalSize, false, [UIScreen mainScreen].scale);
    
//    self.swContentPageDraw(containerView, index: 0, maxIndex: Int(page), drawCallback: { [weak self] () -> Void in
//        let strongSelf = self!
//
//        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        // Recover
//        strongSelf.removeFromSuperview()
//        bakSuperView?.insertSubview(strongSelf, at: bakIndex!)
//
//        strongSelf.frame = bakFrame
//
//        containerView.removeFromSuperview()
//
//        completionHandler(capturedImage)
//    })
    __weak __typeof(self)weakSelf = self;
    [self swContentPageDraw:containerView index:0 maxIndex:page drawCallback:^{
        __strong typeof(self) StrongSelf = weakSelf;
        UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [StrongSelf removeFromSuperview];
        [bakSuperView insertSubview:StrongSelf atIndex:bakIndex];
        StrongSelf.frame = bakFrame;
        [containerView removeFromSuperview];
        completionHandler(capturedImage);
    }];
    
}

- (void)swContentPageDraw:(UIView *)targetView index:(NSInteger)index maxIndex:(NSInteger)maxIndex drawCallback:(void(^)(void))drawCallback
{
    // set up split frame of super view
//    let splitFrame = CGRect(x: 0, y: CGFloat(index) * targetView.frame.size.height, width: targetView.bounds.size.width, height: targetView.frame.size.height)
    CGRect  splitFrame = CGRectMake(0,index * CGRectGetHeight(targetView.bounds), CGRectGetWidth(targetView.bounds), CGRectGetHeight(targetView.bounds));
    // set up webview frame
//    var myFrame = self.frame
    CGRect myFrame = self.frame;
//    myFrame.origin.y = -(CGFloat(index) * targetView.frame.size.height)
    myFrame.origin.y = -index * targetView.frame.size.height;
    self.frame = myFrame;
    
//    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
//        targetView.drawHierarchy(in: splitFrame, afterScreenUpdates: true)
//
//        if index < maxIndex {
//            self.swContentPageDraw(targetView, index: index + 1, maxIndex: maxIndex, drawCallback: drawCallback)
//        }else{
//            drawCallback()
//        }
//    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [targetView drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
        if (index < maxIndex) {
            [self swContentPageDraw:targetView index:index+1 maxIndex:maxIndex drawCallback:drawCallback];
        }else{
            drawCallback();
        }
    });
}

- (void)swContentScrollCapture:(void(^)(UIImage *capturedImage))completionHandler
{
    self.isCapturing = true;
    // Put a fake Cover of View
//    let snapShotView = self.snapshotView(afterScreenUpdates: true)
    UIView * snapShotView = [self  snapshotViewAfterScreenUpdates:YES];
    snapShotView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, CGRectGetWidth(snapShotView.frame), CGRectGetHeight(snapShotView.frame));
//    snapShotView?.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: (snapShotView?.frame.size.width)!, height: (snapShotView?.frame.size.height)!)
//    self.superview?.addSubview(snapShotView!)
    
    // 这里可以加在 superview 上m，用户无感知滑动截屏
//    [self.superview addSubview:snapShotView];
    
    // Backup
    CGPoint bakOffset    = self.scrollView.contentOffset;
    // Divide
    CGFloat page  = floorf(self.scrollView.contentSize.height / CGRectGetHeight(self.bounds));
    
    UIGraphicsBeginImageContextWithOptions(self.scrollView.contentSize, false, [UIScreen mainScreen].scale);
//    swContentScrollPageDraw
    __weak __typeof(self)weakSelf = self;
    [self swContentScrollPageDraw:0 maxIndex:page drawCallback:^{
        __strong typeof(self) StrongSelf = weakSelf;
        UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [StrongSelf.scrollView setContentOffset:bakOffset animated:NO];

//        [snapShotView removeFromSuperview];
        
        StrongSelf.isCapturing = false;
        
        completionHandler(capturedImage);
    }];
    
}

- (void)swContentScrollPageDraw:(NSInteger)index maxIndex:(NSInteger)maxIndex drawCallback:(void(^)(void))drawCallback
{
    
//        [self.scrollView setContentOffset:CGPointMake(0, index * self.scrollView.frame.size.height) animated:false];
    //     let splitFrame = CGRect(x: 0, y: CGFloat(index) * self.scrollView.frame.size.height, width: bounds.size.width, height: bounds.size.height)
    
    [UIView animateWithDuration:1.0 animations:^{
        self.scrollView.contentOffset = CGPointMake(0, index*self.scrollView.frame.size.height);
    } completion:^(BOOL finished) {
        
        CGRect  splitFrame = CGRectMake(0, index * self.scrollView.frame.size.height, self.bounds.size.width, self.bounds.size.height);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
            if (index < maxIndex) {
                [self swContentScrollPageDraw:index + 1 maxIndex:maxIndex drawCallback:drawCallback];
            }else{
                drawCallback();
            }
        });
    }];
}

@end
