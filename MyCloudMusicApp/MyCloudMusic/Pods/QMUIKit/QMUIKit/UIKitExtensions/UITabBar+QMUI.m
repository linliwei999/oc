/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UITabBar+QMUI.m
//  qmui
//
//  Created by QMUI Team on 2017/2/14.
//

#import "UITabBar+QMUI.h"
#import "UITabBar+QMUIBarProtocol.h"
#import "QMUICore.h"
#import "UITabBarItem+QMUI.h"
#import "UIBarItem+QMUI.h"
#import "UIImage+QMUI.h"
#import "UIView+QMUI.h"
#import "UINavigationController+QMUI.h"
#import "UIApplication+QMUI.h"

NSInteger const kLastTouchedTabBarItemIndexNone = -1;
NSString *const kShouldCheckTabBarHiddenKey = @"kShouldCheckTabBarHiddenKey";

@interface UITabBar ()

@property(nonatomic, assign) BOOL canItemRespondDoubleTouch;
@property(nonatomic, assign) NSInteger lastTouchedTabBarItemViewIndex;
@property(nonatomic, assign) NSInteger tabBarItemViewTouchCount;
@end

@implementation UITabBar (QMUI)

QMUISynthesizeBOOLProperty(canItemRespondDoubleTouch, setCanItemRespondDoubleTouch)
QMUISynthesizeNSIntegerProperty(lastTouchedTabBarItemViewIndex, setLastTouchedTabBarItemViewIndex)
QMUISynthesizeNSIntegerProperty(tabBarItemViewTouchCount, setTabBarItemViewTouchCount)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        OverrideImplementation([UITabBar class], @selector(setItems:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^void(UITabBar *selfObject, NSArray<UITabBarItem *> *items, BOOL animated) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, NSArray<UITabBarItem *> *, BOOL);
                originSelectorIMP = (void (*)(id, SEL, NSArray<UITabBarItem *> *, BOOL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, items, animated);
                
                [items enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                    // ?????? tabBarItem ??????????????????????????? item ?????????????????? qmui_view ?????????
                    UIControl *itemView = (UIControl *)item.qmui_view;
                    [itemView addTarget:selfObject action:@selector(handleTabBarItemViewEvent:) forControlEvents:UIControlEventTouchUpInside];
                }];
            };
        });
        
        OverrideImplementation([UITabBar class], @selector(setSelectedItem:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UITabBar *selfObject, UITabBarItem *selectedItem) {
                
                NSInteger olderSelectedIndex = selfObject.selectedItem ? [selfObject.items indexOfObject:selfObject.selectedItem] : -1;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UITabBarItem *);
                originSelectorIMP = (void (*)(id, SEL, UITabBarItem *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, selectedItem);
                
                NSInteger newerSelectedIndex = [selfObject.items indexOfObject:selectedItem];
                // ?????????????????????????????????????????? tabBarItem?????????????????????????????????
                selfObject.canItemRespondDoubleTouch = olderSelectedIndex == newerSelectedIndex;
            };
        });
        
        // iOS 13 ???????????? UITabBarAppearance ???????????? UITabBarItem ??? font ?????????????????????????????? 10??????????????????????????????????????????????????????????????????????????????iOS 14.0 ??????????????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/740
        //
        // iOS 14 ?????? UITabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes[NSForegroundColor] ????????? UITabBarItem ????????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/1110
        //
        // [UIKit Bug] ?????? UITabBarAppearance ??? UITabBarItem ??????????????????????????? bold ????????????????????? title
        // https://github.com/Tencent/QMUI_iOS/issues/1286
        OverrideImplementation(NSClassFromString(@"UITabBarButtonLabel"), @selector(setAttributedText:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UILabel *selfObject, NSAttributedString *firstArgv) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, NSAttributedString *);
                originSelectorIMP = (void (*)(id, SEL, NSAttributedString *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, firstArgv);
                
                if (@available(iOS 14.0, *)) {
                    // iOS 14 ????????? bold ???????????????????????????????????? sizeToFit ??????????????????????????????????????????
                    UIFont *font = selfObject.font;
                    BOOL isBold = [font.fontName containsString:@"bold"];
                    if (isBold) {
                        [selfObject sizeToFit];
                    }
                } else {
                    // iOS 13 ???????????? #1286 ????????????????????????????????? #740 ??????????????????????????????????????? iOS 13 ???????????????
                    [selfObject sizeToFit];
                }
            };
        });
        
        // iOS 14.0 ?????? pop ????????? hidesBottomBarWhenPushed = NO ??? vc???tabBar ????????????????????????
        // ???????????????iOS 14.2 ?????????????????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/1100
        if (@available(iOS 14.0, *)) {
            if (@available(iOS 14.2, *)) {
            } else {
                OverrideImplementation([UINavigationController class], @selector(qmui_didInitialize), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                    return ^(UINavigationController *selfObject) {
                        
                        // call super
                        void (*originSelectorIMP)(id, SEL);
                        originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                        originSelectorIMP(selfObject, originCMD);
                        
                        [selfObject qmui_addNavigationActionDidChangeBlock:^(QMUINavigationAction action, BOOL animated, __kindof UINavigationController * _Nullable weakNavigationController, __kindof UIViewController * _Nullable appearingViewController, NSArray<__kindof UIViewController *> * _Nullable disappearingViewControllers) {
                            switch (action) {
                                case QMUINavigationActionWillPop:
                                case QMUINavigationActionWillSet: {
                                    // ??????????????????????????? push N ??? vc ????????????????????????????????????????????? vc.hidesBottomBarWhenPushed = YES?????? tabBar ??????????????????????????????????????? vc.hidesBottomBarWhenPushed = NO??????????????? pop ???????????????????????????????????????
                                    if (animated && weakNavigationController.tabBarController && !appearingViewController.hidesBottomBarWhenPushed) {
                                        BOOL systemShouldHideTabBar = NO;
                                        
                                        // setViewControllers ?????????????????? vc ??????????????? viewControllers ??????????????????????????????
                                        // https://github.com/Tencent/QMUI_iOS/issues/1177
                                        NSUInteger index = [weakNavigationController.viewControllers indexOfObject:appearingViewController];
                                        
                                        if (index != NSNotFound) {
                                            NSArray<UIViewController *> *viewControllers = [weakNavigationController.viewControllers subarrayWithRange:NSMakeRange(0, index + 1)];
                                            for (UIViewController *vc in viewControllers) {
                                                if (vc.hidesBottomBarWhenPushed) {
                                                    systemShouldHideTabBar = YES;
                                                }
                                            }
                                            if (!systemShouldHideTabBar) {
                                                [weakNavigationController qmui_bindBOOL:YES forKey:kShouldCheckTabBarHiddenKey];
                                            }
                                        }
                                    }
                                }
                                    break;
                                case QMUINavigationActionDidPop:
                                case QMUINavigationActionDidSet: {
                                    [weakNavigationController qmui_bindBOOL:NO forKey:kShouldCheckTabBarHiddenKey];
                                }
                                    break;
                                    
                                default:
                                    break;
                            }
                        }];
                    };
                });
                
                OverrideImplementation([UINavigationController class], NSSelectorFromString(@"_shouldBottomBarBeHidden"), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                    return ^BOOL(UINavigationController *selfObject) {
                        // call super
                        BOOL (*originSelectorIMP)(id, SEL);
                        originSelectorIMP = (BOOL (*)(id, SEL))originalIMPProvider();
                        BOOL result = originSelectorIMP(selfObject, originCMD);
                        
                        if ([selfObject qmui_getBoundBOOLForKey:kShouldCheckTabBarHiddenKey]) {
                            result = NO;
                        }
                        return result;
                    };
                });
            }
        }
        
        
        // ???????????? iOS 12 ?????? UITabBar ??????????????????????????? iOS 13 ???????????????????????????????????????????????????????????????????????????????????????????????????
        // ?????????????????????????????? QMUIConfiguration ????????????????????? appearance ?????????????????? standardAppearance?????????????????? UITabBar ?????????????????? window ???????????????????????????????????????????????????????????????????????? UITabBarAppearance ?????????????????? standardAppearance ?????????????????????????????????????????? UITabBar ?????????????????? standardAppearance?????????????????? moveToWindow ???????????????????????? appearance ?????????????????????????????????????????? window ???????????????????????????
        void (^syncAppearance)(UITabBar *, void(^barActionBlock)(UITabBarAppearance *appearance), void (^itemActionBlock)(UITabBarItemAppearance *itemAppearance)) = ^void(UITabBar *tabBar, void(^barActionBlock)(UITabBarAppearance *appearance), void (^itemActionBlock)(UITabBarItemAppearance *itemAppearance)) {
            if (!barActionBlock && !itemActionBlock) return;
            
            UITabBarAppearance *appearance = tabBar.standardAppearance;
            if (barActionBlock) {
                barActionBlock(appearance);
            }
            if (itemActionBlock) {
                [appearance qmui_applyItemAppearanceWithBlock:itemActionBlock];
            }
            tabBar.standardAppearance = appearance;
#ifdef IOS15_SDK_ALLOWED
            if (@available(iOS 15.0, *)) {
                if (QMUICMIActivated && TabBarUsesStandardAppearanceOnly) {
                    tabBar.scrollEdgeAppearance = appearance;
                }
            }
#endif
        };
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setTintColor:), UIColor *, ^(UITabBar *selfObject, UIColor *tintColor) {
            syncAppearance(selfObject, nil, ^void(UITabBarItemAppearance *itemAppearance) {
                itemAppearance.selected.iconColor = tintColor;
                
                NSMutableDictionary<NSAttributedStringKey, id> *textAttributes = itemAppearance.selected.titleTextAttributes.mutableCopy;
                textAttributes[NSForegroundColorAttributeName] = tintColor;
                itemAppearance.selected.titleTextAttributes = textAttributes.copy;
            });
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setBarTintColor:), UIColor *, ^(UITabBar *selfObject, UIColor *barTintColor) {
            syncAppearance(selfObject, ^void(UITabBarAppearance *appearance) {
                appearance.backgroundColor = barTintColor;
            }, nil);
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setUnselectedItemTintColor:), UIColor *, ^(UITabBar *selfObject, UIColor *tintColor) {
            syncAppearance(selfObject, nil, ^void(UITabBarItemAppearance *itemAppearance) {
                itemAppearance.normal.iconColor = tintColor;
                
                NSMutableDictionary *textAttributes = itemAppearance.normal.titleTextAttributes.mutableCopy;
                textAttributes[NSForegroundColorAttributeName] = tintColor;
                itemAppearance.normal.titleTextAttributes = textAttributes.copy;
            });
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setBackgroundImage:), UIImage *, ^(UITabBar *selfObject, UIImage *image) {
            syncAppearance(selfObject, ^void(UITabBarAppearance *appearance) {
                appearance.backgroundImage = image;
            }, nil);
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setShadowImage:), UIImage *, ^(UITabBar *selfObject, UIImage *shadowImage) {
            syncAppearance(selfObject, ^void(UITabBarAppearance *appearance) {
                appearance.shadowImage = shadowImage;
            }, nil);
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UITabBar class], @selector(setBarStyle:), UIBarStyle, ^(UITabBar *selfObject, UIBarStyle barStyle) {
            syncAppearance(selfObject, ^void(UITabBarAppearance *appearance) {
                appearance.backgroundEffect = [UIBlurEffect effectWithStyle:barStyle == UIBarStyleDefault ? UIBlurEffectStyleSystemChromeMaterialLight : UIBlurEffectStyleSystemChromeMaterialDark];
            }, nil);
        });
    });
}

- (void)handleTabBarItemViewEvent:(UIControl *)itemView {
    
    if (!self.canItemRespondDoubleTouch) {
        return;
    }
    
    if (!self.selectedItem.qmui_doubleTapBlock) {
        return;
    }
    
    // ????????????????????????????????????????????????????????????????????????
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self revertTabBarItemTouch];
    });
    
    NSInteger selectedIndex = [self.items indexOfObject:self.selectedItem];
    
    if (self.lastTouchedTabBarItemViewIndex == kLastTouchedTabBarItemIndexNone) {
        // ???????????????????????? index
        self.lastTouchedTabBarItemViewIndex = selectedIndex;
    } else if (self.lastTouchedTabBarItemViewIndex != selectedIndex) {
        // ?????????????????????????????????????????? index ??????????????????????????????????????????????????????
        [self revertTabBarItemTouch];
        self.lastTouchedTabBarItemViewIndex = selectedIndex;
        return;
    }
    
    self.tabBarItemViewTouchCount ++;
    if (self.tabBarItemViewTouchCount == 2) {
        // ??????????????????????????? tabBarItem?????????????????????
        UITabBarItem *item = self.items[selectedIndex];
        if (item.qmui_doubleTapBlock) {
            item.qmui_doubleTapBlock(item, selectedIndex);
        }
        [self revertTabBarItemTouch];
    }
}

- (void)revertTabBarItemTouch {
    self.lastTouchedTabBarItemViewIndex = kLastTouchedTabBarItemIndexNone;
    self.tabBarItemViewTouchCount = 0;
}

@end

@implementation UITabBarAppearance (QMUI)

- (void)qmui_applyItemAppearanceWithBlock:(void (^)(UITabBarItemAppearance * _Nonnull))block {
    block(self.stackedLayoutAppearance);
    block(self.inlineLayoutAppearance);
    block(self.compactInlineLayoutAppearance);
}

@end
