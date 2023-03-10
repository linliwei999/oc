/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UIViewController+QMUI.m
//  qmui
//
//  Created by QMUI Team on 16/1/12.
//

#import "UIViewController+QMUI.h"
#import "UINavigationController+QMUI.h"
#import "QMUICore.h"
#import "UIInterface+QMUI.h"
#import "NSObject+QMUI.h"
#import "QMUILog.h"
#import "UIView+QMUI.h"

NSNotificationName const QMUIAppSizeWillChangeNotification = @"QMUIAppSizeWillChangeNotification";
NSString *const QMUIPrecedingAppSizeUserInfoKey = @"QMUIPrecedingAppSizeUserInfoKey";
NSString *const QMUIFollowingAppSizeUserInfoKey = @"QMUIFollowingAppSizeUserInfoKey";

@implementation UIViewController (QMUI)

QMUISynthesizeIdCopyProperty(qmui_visibleStateDidChangeBlock, setQmui_visibleStateDidChangeBlock)
QMUISynthesizeIdCopyProperty(qmui_prefersStatusBarHiddenBlock, setQmui_prefersStatusBarHiddenBlock)
QMUISynthesizeIdCopyProperty(qmui_preferredStatusBarStyleBlock, setQmui_preferredStatusBarStyleBlock)
QMUISynthesizeIdCopyProperty(qmui_preferredStatusBarUpdateAnimationBlock, setQmui_preferredStatusBarUpdateAnimationBlock)
QMUISynthesizeIdCopyProperty(qmui_prefersHomeIndicatorAutoHiddenBlock, setQmui_prefersHomeIndicatorAutoHiddenBlock)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        ExchangeImplementations([UIViewController class], @selector(description), @selector(qmuivc_description));
        
        ExtendImplementationOfVoidMethodWithoutArguments([UIViewController class], @selector(viewDidLoad), ^(UIViewController *selfObject) {
            selfObject.qmui_visibleState = QMUIViewControllerViewDidLoad;
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UIViewController class], @selector(viewWillAppear:), BOOL, ^(UIViewController *selfObject, BOOL animated) {
            selfObject.qmui_visibleState = QMUIViewControllerWillAppear;
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UIViewController class], @selector(viewDidAppear:), BOOL, ^(UIViewController *selfObject, BOOL animated) {
            selfObject.qmui_visibleState = QMUIViewControllerDidAppear;
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UIViewController class], @selector(viewWillDisappear:), BOOL, ^(UIViewController *selfObject, BOOL animated) {
            selfObject.qmui_visibleState = QMUIViewControllerWillDisappear;
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UIViewController class], @selector(viewDidDisappear:), BOOL, ^(UIViewController *selfObject, BOOL animated) {
            selfObject.qmui_visibleState = QMUIViewControllerDidDisappear;
        });
        
        OverrideImplementation([UIViewController class], @selector(viewWillTransitionToSize:withTransitionCoordinator:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIViewController *selfObject, CGSize size, id<UIViewControllerTransitionCoordinator> coordinator) {
                
                if (selfObject == UIApplication.sharedApplication.delegate.window.rootViewController) {
                    CGSize originalSize = selfObject.view.frame.size;
                    BOOL sizeChanged = !CGSizeEqualToSize(originalSize, size);
                    if (sizeChanged) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:QMUIAppSizeWillChangeNotification object:nil userInfo:@{QMUIPrecedingAppSizeUserInfoKey: @(originalSize), QMUIFollowingAppSizeUserInfoKey: @(size)}];
                    }
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGSize, id<UIViewControllerTransitionCoordinator>);
                originSelectorIMP = (void (*)(id, SEL, CGSize, id<UIViewControllerTransitionCoordinator>))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, size, coordinator);
            };
        });
        
        // ?????? iOS 11 ????????????UIScrollView ?????????????????????????????? tabBar??????????????? inset ???????????????
        // https://github.com/Tencent/QMUI_iOS/issues/218
        if (!QMUICMIActivated || ShouldFixTabBarSafeAreaInsetsBug) {
            // -[UIViewController _setContentOverlayInsets:andLeftMargin:rightMargin:]
            OverrideImplementation([UIViewController class], NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:%@:",@"setContentOverlayInsets", @"andLeftMargin", @"rightMargin"]), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                return ^(UIViewController *selfObject, UIEdgeInsets insets, CGFloat leftMargin, CGFloat rightMargin) {

                    UITabBarController *tabBarController = selfObject.tabBarController;
                    UITabBar *tabBar = tabBarController.tabBar;
                    if (tabBarController
                        && tabBar
                        && selfObject.navigationController.parentViewController == tabBarController
                        && selfObject.parentViewController == selfObject.navigationController // ?????????????????????????????? childViewController ?????????
                        && !tabBar.hidden
                        && !selfObject.hidesBottomBarWhenPushed
                        && selfObject.isViewLoaded) {
                        CGRect viewRectInTabBarController = [selfObject.view convertRect:selfObject.view.bounds toView:tabBarController.view];

                        // ????????? iOS 13.3 ??????????????? extendedLayoutIncludesOpaqueBars = YES ???????????????????????????????????? vc.view ????????????????????? tabBarController.view??????????????? tabBar ????????? pop ?????? tabBar ?????????????????????navController.view.height ?????????????????????????????? safeAreaInsets.bottom ????????????????????????????????? UIScrollView.contentInset ?????????????????????????????? contentInset ???????????????contentOffset ???????????????????????????????????????????????????????????????
                        // ?????????????????????????????????????????????????????????????????????????????????????????????navController.view.height ???????????????????????? tabBarController.view.height ?????????
                        // https://github.com/Tencent/QMUI_iOS/issues/934
                        if (@available(iOS 13.4, *)) {
                        } else {
                            if ((
                                 (!tabBar.translucent && selfObject.extendedLayoutIncludesOpaqueBars)
                                 || tabBar.translucent
                                 )
                                && selfObject.edgesForExtendedLayout & UIRectEdgeBottom
                                && !CGFloatEqualToFloat(CGRectGetHeight(viewRectInTabBarController), CGRectGetHeight(tabBarController.view.bounds))) {
                                return;
                            }
                        }

                        // pop ????????????????????????????????? tabBar ??????????????? view ?????????????????????????????????????????????????????? convertRect ??????
                        CGRect barRectInTabBarController = tabBar.window ? [tabBar convertRect:tabBar.bounds toView:tabBarController.view] : tabBar.frame;
                        CGFloat correctInsetBottom = MAX(CGRectGetMaxY(viewRectInTabBarController) - CGRectGetMinY(barRectInTabBarController), 0);
                        insets.bottom = correctInsetBottom;
                    }

                    // call super
                    void (*originSelectorIMP)(id, SEL, UIEdgeInsets, CGFloat, CGFloat);
                    originSelectorIMP = (void (*)(id, SEL, UIEdgeInsets, CGFloat, CGFloat))originalIMPProvider();
                    originSelectorIMP(selfObject, originCMD, insets, leftMargin, rightMargin);
                };
            });
        }
        
        // iOS 11 ???????????? override prefersStatusBarHidden ??????????????????????????????????????????????????????????????? +[UIViewController doesOverrideViewControllerMethod:inBaseClass:] ???????????????????????? UIViewController ??????????????? prefersStatusBarHidden ????????????????????????????????? prefersStatusBarHidden????????????????????? swizzle ?????????????????? prefersStatusBarHidden?????????????????????????????????????????????????????????????????????????????? block ??????????????? iOS 10 ?????????????????????????????????????????????????????????
        // ?????????????????? hidden ??????????????????????????? style???animation ???????????????????????? iOS ????????????????????????????????????
        OverrideImplementation([UIViewController class], NSSelectorFromString(@"_preferredStatusBarVisibility"), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^NSInteger(UIViewController *selfObject) {
                // ?????????????????? prefersStatusBarHidden ??????????????? block ??????????????????????????? qmui_hasOverrideUIKitMethod ??????
                if (![selfObject qmui_hasOverrideUIKitMethod:@selector(prefersStatusBarHidden)] && selfObject.qmui_prefersStatusBarHiddenBlock) {
                    return selfObject.qmui_prefersStatusBarHiddenBlock() ? 1 : 2;// ??????????????? 1 ???????????????2 ???????????????0 ???????????????
                }

                // call super
                NSInteger (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (NSInteger (*)(id, SEL))originalIMPProvider();
                NSInteger result = originSelectorIMP(selfObject, originCMD);
                return result;
            };
        });
        
        OverrideImplementation([UIViewController class], @selector(preferredStatusBarStyle), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^UIStatusBarStyle(UIViewController *selfObject) {
                if (selfObject.qmui_preferredStatusBarStyleBlock) {
                    return selfObject.qmui_preferredStatusBarStyleBlock();
                }
                
                // call super
                UIStatusBarStyle (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (UIStatusBarStyle (*)(id, SEL))originalIMPProvider();
                UIStatusBarStyle result = originSelectorIMP(selfObject, originCMD);
                return result;
            };
        });
        
        OverrideImplementation([UIViewController class], @selector(preferredStatusBarUpdateAnimation), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^UIStatusBarAnimation(UIViewController *selfObject) {
                if (selfObject.qmui_preferredStatusBarUpdateAnimationBlock) {
                    return selfObject.qmui_preferredStatusBarUpdateAnimationBlock();
                }
                
                // call super
                UIStatusBarAnimation (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (UIStatusBarAnimation (*)(id, SEL))originalIMPProvider();
                UIStatusBarAnimation result = originSelectorIMP(selfObject, originCMD);
                return result;
            };
        });
        
        OverrideImplementation([UIViewController class], @selector(prefersHomeIndicatorAutoHidden), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^BOOL(UIViewController *selfObject) {
                if (selfObject.qmui_prefersHomeIndicatorAutoHiddenBlock) {
                    return selfObject.qmui_prefersHomeIndicatorAutoHiddenBlock();
                }
                
                // call super
                BOOL (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (BOOL (*)(id, SEL))originalIMPProvider();
                BOOL result = originSelectorIMP(selfObject, originCMD);
                return result;
            };
        });
    });
}

- (NSString *)qmuivc_description {
    if (![NSThread isMainThread]) {
        return [self qmuivc_description];
    }
    
    NSString *result = [NSString stringWithFormat:@"%@; superclass: %@; title: %@; view: %@", [self qmuivc_description], NSStringFromClass(self.superclass), self.title, [self isViewLoaded] ? self.view : nil];
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navController = (UINavigationController *)self;
        NSString *navDescription = [NSString stringWithFormat:@"; viewControllers(%@): %@; topViewController: %@; visibleViewController: %@", @(navController.viewControllers.count), [self descriptionWithViewControllers:navController.viewControllers], [navController.topViewController qmuivc_description], [navController.visibleViewController qmuivc_description]];
        result = [result stringByAppendingString:navDescription];
        
    } else if ([self isKindOfClass:[UITabBarController class]]) {
        
        UITabBarController *tabBarController = (UITabBarController *)self;
        NSString *tabBarDescription = [NSString stringWithFormat:@"; viewControllers(%@): %@; selectedViewController(%@): %@", @(tabBarController.viewControllers.count), [self descriptionWithViewControllers:tabBarController.viewControllers], @(tabBarController.selectedIndex), [tabBarController.selectedViewController qmuivc_description]];
        result = [result stringByAppendingString:tabBarDescription];
        
    }
    return result;
}

- (NSString *)descriptionWithViewControllers:(NSArray<UIViewController *> *)viewControllers {
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:@"( "];
    for (NSInteger i = 0, l = viewControllers.count; i < l; i++) {
        [string appendFormat:@"[%@]%@%@", @(i), [viewControllers[i] qmuivc_description], i < l - 1 ? @"," : @""];
    }
    [string appendString:@" )"];
    return [string copy];
}

+ (BOOL)qmui_isSystemContainerViewController {
    for (Class clz in @[UINavigationController.class, UITabBarController.class, UISplitViewController.class]) {
        if ([self isSubclassOfClass:clz]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)qmui_isSystemContainerViewController {
    return self.class.qmui_isSystemContainerViewController;
}

static char kAssociatedObjectKey_visibleState;
- (void)setQmui_visibleState:(QMUIViewControllerVisibleState)qmui_visibleState {
    BOOL valueChanged = self.qmui_visibleState != qmui_visibleState;
    objc_setAssociatedObject(self, &kAssociatedObjectKey_visibleState, @(qmui_visibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.qmui_visibleStateDidChangeBlock) {
        self.qmui_visibleStateDidChangeBlock(self, qmui_visibleState);
    }
}

- (QMUIViewControllerVisibleState)qmui_visibleState {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_visibleState)) unsignedIntegerValue];
}

- (UIViewController *)qmui_previousViewController {
    NSArray<UIViewController *> *viewControllers = self.navigationController.viewControllers;
    NSUInteger index = [viewControllers indexOfObject:self];
    if (index != NSNotFound && index > 0) {
        return viewControllers[index - 1];
    }
    return nil;
}

- (NSString *)qmui_previousViewControllerTitle {
    UIViewController *previousViewController = [self qmui_previousViewController];
    if (previousViewController) {
        return previousViewController.title ?: previousViewController.navigationItem.title;
    }
    return nil;
}

- (BOOL)qmui_isPresented {
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.qmui_rootViewController != self) {
            return NO;
        }
        viewController = self.navigationController;
    }
    BOOL result = viewController.presentingViewController.presentedViewController == viewController;
    return result;
}

- (UIViewController *)qmui_visibleViewControllerIfExist {
    
    if (self.presentedViewController) {
        return [self.presentedViewController qmui_visibleViewControllerIfExist];
    }
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        return [((UINavigationController *)self).visibleViewController qmui_visibleViewControllerIfExist];
    }
    
    if ([self isKindOfClass:[UITabBarController class]]) {
        return [((UITabBarController *)self).selectedViewController qmui_visibleViewControllerIfExist];
    }
    
    if ([self qmui_isViewLoadedAndVisible]) {
        return self;
    } else {
        QMUILog(@"UIViewController (QMUI)", @"qmui_visibleViewControllerIfExist:?????????????????????viewController???self = %@, self.view.window = %@", self, [self isViewLoaded] ? self.view.window : nil);
        return nil;
    }
}

- (BOOL)qmui_isViewLoadedAndVisible {
    return self.isViewLoaded && self.view.qmui_visible;
}

- (CGFloat)qmui_navigationBarMaxYInViewCoordinator {
    if (!self.isViewLoaded) {
        return 0;
    }
    
    // ????????????????????? self.navigationController ????????????????????????????????????????????? view ??????????????????????????? navigationController ?????????
    UINavigationController *navigationController = self.navigationController;
    if (!navigationController) {
        navigationController = self.view.superview.superview.qmui_viewController;
        if (![navigationController isKindOfClass:[UINavigationController class]]) {
            navigationController = nil;
        }
    }
    
    if (!navigationController) {
        return 0;
    }
    
    UINavigationBar *navigationBar = navigationController.navigationBar;
    CGFloat barMinX = CGRectGetMinX(navigationBar.frame);
    CGFloat barPresentationMinX = CGRectGetMinX(navigationBar.layer.presentationLayer.frame);
    CGFloat superviewX = CGRectGetMinX(self.view.superview.frame);
    CGFloat superviewX2 = CGRectGetMinX(self.view.superview.superview.frame);
    
    if (self.qmui_navigationControllerPoppingInteracted) {
        if (barMinX != 0 && barMinX == barPresentationMinX) {
            // ???????????? bar ?????????
            return 0;
        } else if (barMinX > 0) {
            if (self.qmui_willAppearByInteractivePopGestureRecognizer) {
                // ?????????????????????????????????????????? bar
                return 0;
            }
        } else if (barMinX < 0) {
            // ?????????????????????????????????????????? bar
            if (!self.qmui_willAppearByInteractivePopGestureRecognizer) {
                return 0;
            }
        } else {
            // ?????????????????????????????????????????? bar
            if (barPresentationMinX != 0 && !self.qmui_willAppearByInteractivePopGestureRecognizer) {
                return 0;
            }
        }
    } else {
        if (barMinX > 0) {
            // ?????? pop ?????? bar ?????????
            if (superviewX2 <= 0) {
                // ???????????????????????? bar ?????????
                return 0;
            }
        } else if (barMinX < 0) {
            if (barPresentationMinX < 0) {
                // ?????? bar push ?????? bar ?????????
                return 0;
            }
            // ???????????? bar ????????? push ?????? bar ????????????bar ?????????????????????????????????????????????
            if (superviewX >= 0) {
                // ???????????????????????? bar ?????????
                return 0;
            }
        } else {
            if (superviewX < 0 && barPresentationMinX != 0) {
                // ??? bar push ?????? bar ????????????????????????????????? bar ?????????
                return 0;
            }
            if (superviewX2 > 0 && barPresentationMinX < 0) {
                // ??? bar pop ?????? bar ?????????????????? pop ??????????????? bar ?????????
                return 0;
            }
        }
    }
    
    CGRect navigationBarFrameInView = [self.view convertRect:navigationBar.frame fromView:navigationBar.superview];
    CGRect navigationBarFrame = CGRectIntersection(self.view.bounds, navigationBarFrameInView);
    
    // ?????? rect ????????????????????????CGRectIntersection ?????????????????????????????? rect???????????????????????????
    if (!CGRectIsValidated(navigationBarFrame)) {
        return 0;
    }
    
    CGFloat result = CGRectGetMaxY(navigationBarFrame);
    return result;
}

- (CGFloat)qmui_toolbarSpacingInViewCoordinator {
    if (!self.isViewLoaded) {
        return 0;
    }
    if (!self.navigationController.toolbar || self.navigationController.toolbarHidden) {
        return 0;
    }
    CGRect toolbarFrame = CGRectIntersection(self.view.bounds, [self.view convertRect:self.navigationController.toolbar.frame fromView:self.navigationController.toolbar.superview]);
    
    // ?????? rect ????????????????????????CGRectIntersection ?????????????????????????????? rect???????????????????????????
    if (!CGRectIsValidated(toolbarFrame)) {
        return 0;
    }
    
    CGFloat result = CGRectGetHeight(self.view.bounds) - CGRectGetMinY(toolbarFrame);
    return result;
}

- (CGFloat)qmui_tabBarSpacingInViewCoordinator {
    if (!self.isViewLoaded) {
        return 0;
    }
    if (!self.tabBarController.tabBar || self.tabBarController.tabBar.hidden) {
        return 0;
    }
    if (self.hidesBottomBarWhenPushed && self.navigationController.qmui_rootViewController != self) {
        return 0;
    }
    
    CGRect tabBarFrame = CGRectIntersection(self.view.bounds, [self.view convertRect:self.tabBarController.tabBar.frame fromView:self.tabBarController.tabBar.superview]);
    
    // ?????? rect ????????????????????????CGRectIntersection ?????????????????????????????? rect???????????????????????????
    if (!CGRectIsValidated(tabBarFrame)) {
        return 0;
    }
    
    CGFloat result = CGRectGetHeight(self.view.bounds) - CGRectGetMinY(tabBarFrame);
    return result;
}

- (BOOL)qmui_prefersStatusBarHidden {
    if (self.childViewControllerForStatusBarHidden) {
        return self.childViewControllerForStatusBarHidden.qmui_prefersStatusBarHidden;
    }
    return self.prefersStatusBarHidden;
}

- (UIStatusBarStyle)qmui_preferredStatusBarStyle {
    if (self.childViewControllerForStatusBarStyle) {
        return self.childViewControllerForStatusBarStyle.qmui_preferredStatusBarStyle;
    }
    return self.preferredStatusBarStyle;
}

- (BOOL)qmui_prefersLargeTitleDisplayed {
    QMUIAssert(self.navigationController, @"UIViewController (QMUI)", @"%s ????????? navigationController ????????????????????????", __func__);
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (!navigationBar.prefersLargeTitles) {
        return NO;
    }
    if (self.navigationItem.largeTitleDisplayMode == UINavigationItemLargeTitleDisplayModeAlways) {
        return YES;
    } else if (self.navigationItem.largeTitleDisplayMode == UINavigationItemLargeTitleDisplayModeNever) {
        return NO;
    } else if (self.navigationItem.largeTitleDisplayMode == UINavigationItemLargeTitleDisplayModeAutomatic) {
        if (self.navigationController.viewControllers.firstObject == self) {
            return YES;
        } else {
            UIViewController *previousViewController = self.navigationController.viewControllers[[self.navigationController.viewControllers indexOfObject:self] - 1];
            return previousViewController.qmui_prefersLargeTitleDisplayed == YES;
        }
    }
    return NO;
}

- (BOOL)qmui_isDescendantOfViewController:(UIViewController *)viewController {
    UIViewController *parentViewController = self;
    while (parentViewController) {
        if (parentViewController == viewController) {
            return YES;
        }
        parentViewController = parentViewController.parentViewController;
    }
    return NO;
}

@end

@implementation UIViewController (Data)

QMUISynthesizeIdCopyProperty(qmui_didAppearAndLoadDataBlock, setQmui_didAppearAndLoadDataBlock)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ExtendImplementationOfVoidMethodWithSingleArgument([UIViewController class], @selector(viewDidAppear:), BOOL, ^(UIViewController *selfObject, BOOL animated) {
            if (selfObject.qmui_didAppearAndLoadDataBlock && selfObject.qmui_dataLoaded) {
                selfObject.qmui_didAppearAndLoadDataBlock();
                selfObject.qmui_didAppearAndLoadDataBlock = nil;
            }
        });
    });
}

static char kAssociatedObjectKey_dataLoaded;
- (void)setQmui_dataLoaded:(BOOL)qmui_dataLoaded {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_dataLoaded, @(qmui_dataLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.qmui_didAppearAndLoadDataBlock && qmui_dataLoaded && self.qmui_visibleState >= QMUIViewControllerDidAppear) {
        self.qmui_didAppearAndLoadDataBlock();
        self.qmui_didAppearAndLoadDataBlock = nil;
    }
}

- (BOOL)isQmui_dataLoaded {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_dataLoaded)) boolValue];
}

@end

@implementation UIViewController (Runtime)

- (BOOL)qmui_hasOverrideUIKitMethod:(SEL)selector {
    // ???????????? Xcode Interface Builder ???????????????????????????????????????????????????
    NSMutableArray<Class> *viewControllerSuperclasses = [[NSMutableArray alloc] initWithObjects:
                                               [UIImagePickerController class],
                                               [UINavigationController class],
                                               [UITableViewController class],
                                               [UICollectionViewController class],
                                               [UITabBarController class],
                                               [UISplitViewController class],
                                               [UIPageViewController class],
                                               [UIViewController class],
                                               nil];
    
    if (NSClassFromString(@"UIAlertController")) {
        [viewControllerSuperclasses addObject:[UIAlertController class]];
    }
    if (NSClassFromString(@"UISearchController")) {
        [viewControllerSuperclasses addObject:[UISearchController class]];
    }
    for (NSInteger i = 0, l = viewControllerSuperclasses.count; i < l; i++) {
        Class superclass = viewControllerSuperclasses[i];
        if ([self qmui_hasOverrideMethod:selector ofSuperclass:superclass]) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation UIViewController (QMUINavigationController)

QMUISynthesizeBOOLProperty(qmui_navigationControllerPopGestureRecognizerChanging, setQmui_navigationControllerPopGestureRecognizerChanging)
QMUISynthesizeBOOLProperty(qmui_poppingByInteractivePopGestureRecognizer, setQmui_poppingByInteractivePopGestureRecognizer)
QMUISynthesizeBOOLProperty(qmui_willAppearByInteractivePopGestureRecognizer, setQmui_willAppearByInteractivePopGestureRecognizer)

- (BOOL)qmui_navigationControllerPoppingInteracted {
    return self.qmui_poppingByInteractivePopGestureRecognizer || self.qmui_willAppearByInteractivePopGestureRecognizer;
}

- (void)qmui_animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
                             completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion {
    if (self.transitionCoordinator) {
        BOOL animationQueuedToRun = [self.transitionCoordinator animateAlongsideTransition:animation completion:completion];
        // ????????????????????? animateAlongsideTransition ??? animation ??????????????????????????????????????????????????????
        // ??????????????????completion ?????????????????????????????????????????????????????????????????? completion ??? animation block ?????????
        // ???????????????????????? B ???????????? A ??????????????????????????????animation ???????????????
        // https://github.com/Tencent/QMUI_iOS/issues/692
        if (!animationQueuedToRun && animation) {
            animation(nil);
        }
    } else {
        if (animation) animation(nil);
        if (completion) completion(nil);
    }
}

@end

@implementation QMUIHelper (ViewController)

+ (nullable UIViewController *)visibleViewController {
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    UIViewController *visibleViewController = [rootViewController qmui_visibleViewControllerIfExist];
    return visibleViewController;
}

@end
