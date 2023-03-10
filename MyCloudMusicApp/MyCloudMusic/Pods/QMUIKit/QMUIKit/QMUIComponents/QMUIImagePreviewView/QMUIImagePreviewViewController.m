/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  QMUIImagePreviewViewController.m
//  qmui
//
//  Created by QMUI Team on 2016/11/30.
//

#import "QMUIImagePreviewViewController.h"
#import "QMUICore.h"
#import "QMUIImagePreviewViewTransitionAnimator.h"
#import "UIInterface+QMUI.h"
#import "UIView+QMUI.h"
#import "UIViewController+QMUI.h"
#import "QMUIAppearance.h"

const CGFloat QMUIImagePreviewViewControllerCornerRadiusAutomaticDimension = -1;

@implementation QMUIImagePreviewViewController (UIAppearance)

+ (instancetype)appearance {
    return [QMUIAppearance appearanceForClass:self];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initAppearance];
    });
}

+ (void)initAppearance {
    QMUIImagePreviewViewController.appearance.backgroundColor = UIColorBlack;
}

@end

@interface QMUIImagePreviewViewController ()

@property(nonatomic, strong) UIPanGestureRecognizer *dismissingGesture;
@property(nonatomic, assign) CGPoint gestureBeganLocation;
@property(nonatomic, weak) QMUIZoomImageView *gestureZoomImageView;
@property(nonatomic, assign) BOOL canShowPresentingViewControllerWhenGesturing;
@property(nonatomic, assign) BOOL originalStatusBarHidden;
@property(nonatomic, assign) BOOL statusBarHidden;
@end

@implementation QMUIImagePreviewViewController

- (void)didInitialize {
    [super didInitialize];
    
    self.sourceImageCornerRadius = QMUIImagePreviewViewControllerCornerRadiusAutomaticDimension;
    
    _dismissingGestureEnabled = YES;
    
    [self qmui_applyAppearance];
    
    self.qmui_prefersHomeIndicatorAutoHiddenBlock = ^BOOL{
        return YES;
    };

    
    // present style
    self.transitioningAnimator = [[QMUIImagePreviewViewTransitionAnimator alloc] init];
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.transitioningDelegate = self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    if ([self isViewLoaded]) {
        self.view.backgroundColor = backgroundColor;
    }
}

@synthesize imagePreviewView = _imagePreviewView;
- (QMUIImagePreviewView *)imagePreviewView {
    if (!_imagePreviewView) {
        _imagePreviewView = [[QMUIImagePreviewView alloc] initWithFrame:self.isViewLoaded ? self.view.bounds : CGRectZero];
    }
    return _imagePreviewView;
}

- (void)initSubviews {
    [super initSubviews];
    self.view.backgroundColor = self.backgroundColor;
    [self.view addSubview:self.imagePreviewView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.imagePreviewView.qmui_frameApplyTransform = self.view.bounds;
    
    UIViewController *backendViewController = [self visibleViewControllerWithViewController:self.presentingViewController];
    self.canShowPresentingViewControllerWhenGesturing = [QMUIHelper interfaceOrientationMask:backendViewController.supportedInterfaceOrientations containsInterfaceOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.qmui_isPresented) {
        [self initObjectsForZoomStyleIfNeeded];
    }
    [self.imagePreviewView.collectionView reloadData];
    [self.imagePreviewView.collectionView layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.qmui_isPresented) {
        self.statusBarHidden = YES;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.statusBarHidden = self.originalStatusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeObjectsForZoomStyle];
    [self resetDismissingGesture];
}

- (void)setPresentingStyle:(QMUIImagePreviewViewControllerTransitioningStyle)presentingStyle {
    _presentingStyle = presentingStyle;
    self.dismissingStyle = presentingStyle;
}

- (void)setTransitioningAnimator:(__kindof QMUIImagePreviewViewTransitionAnimator *)transitioningAnimator {
    _transitioningAnimator = transitioningAnimator;
    transitioningAnimator.imagePreviewViewController = self;
}

- (BOOL)prefersStatusBarHidden {
    if (self.qmui_visibleState < QMUIViewControllerDidAppear || self.qmui_visibleState >= QMUIViewControllerDidDisappear) {
        // ??? present/dismiss ????????????????????????????????????????????????????????????
        if (self.presentingViewController) {
            BOOL statusBarHidden = self.presentingViewController.view.window.windowScene.statusBarManager.statusBarHidden;
            self.originalStatusBarHidden = statusBarHidden;
            return self.originalStatusBarHidden;
        }
        return [super prefersStatusBarHidden];
    }
    return self.statusBarHidden;
}

#pragma mark - ??????

- (void)initObjectsForZoomStyleIfNeeded {
    if (!self.dismissingGesture && self.dismissingGestureEnabled) {
        self.dismissingGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissingPreviewGesture:)];
        [self.view addGestureRecognizer:self.dismissingGesture];
    }
}

- (void)removeObjectsForZoomStyle {
    [self.dismissingGesture removeTarget:self action:@selector(handleDismissingPreviewGesture:)];
    [self.view removeGestureRecognizer:self.dismissingGesture];
    self.dismissingGesture = nil;
}

- (void)handleDismissingPreviewGesture:(UIPanGestureRecognizer *)gesture {
    
    if (!self.dismissingGestureEnabled) return;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.gestureBeganLocation = [gesture locationInView:self.view];
            self.gestureZoomImageView = [self.imagePreviewView zoomImageViewAtIndex:self.imagePreviewView.currentImageIndex];
            self.gestureZoomImageView.scrollView.clipsToBounds = NO;// ??? contentView ?????????????????????????????? clipToBounds?????????????????????????????????contentView ????????????????????????????????????
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint location = [gesture locationInView:self.view];
            CGFloat horizontalDistance = location.x - self.gestureBeganLocation.x;
            CGFloat verticalDistance = location.y - self.gestureBeganLocation.y;
            CGFloat ratio = 1.0;
            CGFloat alpha = 1.0;
            if (verticalDistance > 0) {
                // ???????????????????????????????????????????????????????????????????????????????????????
                ratio = 1.0 - verticalDistance / CGRectGetHeight(self.view.bounds) / 2;
                
                // ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
                if (self.canShowPresentingViewControllerWhenGesturing) {
                    alpha = 1.0 - verticalDistance / CGRectGetHeight(self.view.bounds) * 1.8;
                }
            } else {
                // ??????????????????????????????????????????????????????????????????????????????????????????
                CGFloat a = self.gestureBeganLocation.y + 100;// ??????????????????????????????????????????????????????????????????????????????
                CGFloat b = 1 - pow((a - fabs(verticalDistance)) / a, 2);
                CGFloat contentViewHeight = CGRectGetHeight(self.gestureZoomImageView.contentViewRectInZoomImageView);
                CGFloat c = (CGRectGetHeight(self.view.bounds) - contentViewHeight) / 2;
                verticalDistance = -c * b;
            }
            CGAffineTransform transform = CGAffineTransformMakeTranslation(horizontalDistance, verticalDistance);
            transform = CGAffineTransformScale(transform, ratio, ratio);
            self.gestureZoomImageView.transform = transform;
            self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:alpha];
            BOOL statusBarHidden = alpha >= 1 ? YES : self.originalStatusBarHidden;
            if (statusBarHidden != self.statusBarHidden) {
                self.statusBarHidden = statusBarHidden;
                [self setNeedsStatusBarAppearanceUpdate];
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            CGPoint location = [gesture locationInView:self.view];
            CGFloat verticalDistance = location.y - self.gestureBeganLocation.y;
            if (verticalDistance > CGRectGetHeight(self.view.bounds) / 2 / 3) {
                
                // ???????????????????????????????????????????????????????????????????????????????????????????????? dismiss ?????????????????????????????????????????????????????????????????? viewWillAppear??????????????? AutomaticallyRotateDeviceOrientation ????????????????????????????????????????????????????????????????????????????????????????????? viewWillAppear: ??????????????? animator ??? animateTransition: ??????????????????????????????????????????????????? viewWillAppear: ???????????????
                // ????????????????????????????????? dismiss???????????????????????????????????? dismiss ???????????????????????????????????????
                if (!self.canShowPresentingViewControllerWhenGesturing) {
                    [self.presentingViewController beginAppearanceTransition:YES animated:YES];
                }
                
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self cancelDismissingGesture];
            }
        }
            break;
        default:
            [self cancelDismissingGesture];
            break;
    }
}

// ????????????????????????????????????????????????
- (void)cancelDismissingGesture {
    self.statusBarHidden = YES;
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
        [self resetDismissingGesture];
    } completion:NULL];
}

// ???????????????????????????
- (void)resetDismissingGesture {
    self.gestureZoomImageView.transform = CGAffineTransformIdentity;
    self.gestureBeganLocation = CGPointZero;
    self.gestureZoomImageView = nil;
    self.view.backgroundColor = self.backgroundColor;
}

// ????????? qmui_visibleViewControllerIfExist ????????????????????? presentedViewController
- (UIViewController *)visibleViewControllerWithViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [self visibleViewControllerWithViewController:((UINavigationController *)viewController).topViewController];
    }
    
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self visibleViewControllerWithViewController:((UITabBarController *)viewController).selectedViewController];
    }
    
    return viewController;
}

#pragma mark - <UIViewControllerTransitioningDelegate>

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self.transitioningAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.transitioningAnimator;
}

@end
