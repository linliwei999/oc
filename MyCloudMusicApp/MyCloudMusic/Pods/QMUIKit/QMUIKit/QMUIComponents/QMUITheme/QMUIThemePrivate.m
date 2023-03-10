/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */
//
//  QMUIThemePrivate.m
//  QMUIKit
//
//  Created by MoLice on 2019/J/26.
//

#import "QMUIThemePrivate.h"
#import "QMUICore.h"
#import "UIColor+QMUI.h"
#import "UIVisualEffect+QMUITheme.h"
#import "UIView+QMUITheme.h"
#import "UISlider+QMUI.h"
#import "UIView+QMUI.h"
#import "UISearchBar+QMUI.h"
#import "UITableViewCell+QMUI.h"
#import "CALayer+QMUI.h"
#import "UIVisualEffectView+QMUI.h"
#import "UIBarItem+QMUI.h"
#import "UITabBar+QMUI.h"
#import "UITabBarItem+QMUI.h"

// QMUI classes
#import "QMUIImagePickerCollectionViewCell.h"
#import "QMUIAlertController.h"
#import "QMUIButton.h"
#import "QMUIConsole.h"
#import "QMUIEmotionView.h"
#import "QMUIEmptyView.h"
#import "QMUIGridView.h"
#import "QMUIImagePreviewView.h"
#import "QMUILabel.h"
#import "QMUIPopupContainerView.h"
#import "QMUIPopupMenuButtonItem.h"
#import "QMUIPopupMenuView.h"
#import "QMUITextField.h"
#import "QMUITextView.h"
#import "QMUIToastBackgroundView.h"
#import "QMUIBadgeProtocol.h"

@interface QMUIThemePropertiesRegister : NSObject

@end

@implementation QMUIThemePropertiesRegister

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ExtendImplementationOfNonVoidMethodWithSingleArgument([UIView class], @selector(initWithFrame:), CGRect, UIView *, ^UIView *(UIView *selfObject, CGRect frame, UIView *originReturnValue) {
            ({
                static NSDictionary<NSString *, NSArray<NSString *> *> *classRegisters = nil;
                if (!classRegisters) {
                    classRegisters = @{
                                       NSStringFromClass(UISlider.class):                   @[NSStringFromSelector(@selector(minimumTrackTintColor)),
                                                                                              NSStringFromSelector(@selector(maximumTrackTintColor)),
                                                                                              NSStringFromSelector(@selector(thumbTintColor)),
                                                                                              NSStringFromSelector(@selector(qmui_thumbColor))],
                                       NSStringFromClass(UISwitch.class):                   @[NSStringFromSelector(@selector(onTintColor)),
                                                                                              NSStringFromSelector(@selector(thumbTintColor)),],
                                       NSStringFromClass(UIActivityIndicatorView.class):    @[NSStringFromSelector(@selector(color)),],
                                       NSStringFromClass(UIProgressView.class):             @[NSStringFromSelector(@selector(progressTintColor)),
                                                                                              NSStringFromSelector(@selector(trackTintColor)),],
                                       NSStringFromClass(UIPageControl.class):              @[NSStringFromSelector(@selector(pageIndicatorTintColor)),
                                                                                              NSStringFromSelector(@selector(currentPageIndicatorTintColor)),],
                                       NSStringFromClass(UITableView.class):                @[NSStringFromSelector(@selector(backgroundColor)),
                                                                                              NSStringFromSelector(@selector(sectionIndexColor)),
                                                                                              NSStringFromSelector(@selector(sectionIndexBackgroundColor)),
                                                                                              NSStringFromSelector(@selector(sectionIndexTrackingBackgroundColor)),
                                                                                              NSStringFromSelector(@selector(separatorColor)),],
                                       NSStringFromClass(UITableViewCell.class):            @[NSStringFromSelector(@selector(qmui_selectedBackgroundColor)),],
                                       NSStringFromClass(UICollectionViewCell.class):            @[NSStringFromSelector(@selector(qmui_selectedBackgroundColor)),],
                                       NSStringFromClass(UINavigationBar.class):                   ({
                                           NSMutableArray<NSString *> *result = @[
                                               NSStringFromSelector(@selector(qmui_effect)),
                                               NSStringFromSelector(@selector(qmui_effectForegroundColor)),
                                           ].mutableCopy;
                                           if (@available(iOS 15.0, *)) {
                                               // iOS 15 ??? UINavigationBar (QMUI) ???????????????????????????????????? standardAppearance??????????????????????????? standardAppearance ???????????????????????????
                                               [result addObject:NSStringFromSelector(@selector(standardAppearance))];
                                           } else {
                                               [result addObjectsFromArray:@[NSStringFromSelector(@selector(barTintColor)),]];
                                           }
                                           result.copy;
                                       }),
                                       NSStringFromClass(UIToolbar.class):                  @[NSStringFromSelector(@selector(barTintColor)),],
                                       NSStringFromClass(UITabBar.class):                   @[
                                           NSStringFromSelector(@selector(qmui_effect)),
                                           NSStringFromSelector(@selector(qmui_effectForegroundColor)),
                                           NSStringFromSelector(@selector(standardAppearance)),
                                       ],
                                       NSStringFromClass(UISearchBar.class):                        @[NSStringFromSelector(@selector(barTintColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_placeholderColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_textColor)),],
                                       NSStringFromClass(UITextField.class):                        @[NSStringFromSelector(@selector(attributedText)),],
                                       NSStringFromClass(UIView.class):                             @[NSStringFromSelector(@selector(tintColor)),
                                                                                                      NSStringFromSelector(@selector(backgroundColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_borderColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_badgeBackgroundColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_badgeTextColor)),
                                                                                                      NSStringFromSelector(@selector(qmui_updatesIndicatorColor)),],
                                       NSStringFromClass(UIVisualEffectView.class):                 @[NSStringFromSelector(@selector(effect)),
                                                                                                      NSStringFromSelector(@selector(qmui_foregroundColor))],
                                       NSStringFromClass(UIImageView.class):                        @[NSStringFromSelector(@selector(image))],
                                       
                                       // QMUI classes
                                       NSStringFromClass(QMUIImagePickerCollectionViewCell.class):  @[NSStringFromSelector(@selector(videoDurationLabelTextColor)),],
                                       NSStringFromClass(QMUIButton.class):                         @[
                                           // tintColorAdjustsTitleAndImage ?????????????????? tintColor???tintColor ?????????????????????????????????????????????
                                           // https://github.com/Tencent/QMUI_iOS/issues/1452
                                           // NSStringFromSelector(@selector(tintColorAdjustsTitleAndImage)),
                                                                                                      NSStringFromSelector(@selector(highlightedBackgroundColor)),
                                                                                                      NSStringFromSelector(@selector(highlightedBorderColor)),],
                                       NSStringFromClass(QMUIConsole.class):                        @[NSStringFromSelector(@selector(searchResultHighlightedBackgroundColor)),],
                                       NSStringFromClass(QMUIEmotionView.class):                    @[NSStringFromSelector(@selector(sendButtonBackgroundColor)),],
                                       NSStringFromClass(QMUIEmptyView.class):                      @[NSStringFromSelector(@selector(textLabelTextColor)),
                                                                                                      NSStringFromSelector(@selector(detailTextLabelTextColor)),
                                                                                                      NSStringFromSelector(@selector(actionButtonTitleColor))],
                                       NSStringFromClass(QMUIGridView.class):                       @[NSStringFromSelector(@selector(separatorColor)),],
                                       NSStringFromClass(QMUIImagePreviewView.class):               @[NSStringFromSelector(@selector(loadingColor)),],
                                       NSStringFromClass(QMUILabel.class):                          @[NSStringFromSelector(@selector(highlightedBackgroundColor)),],
                                       NSStringFromClass(QMUIPopupContainerView.class):             @[NSStringFromSelector(@selector(highlightedBackgroundColor)),
                                                                                                      NSStringFromSelector(@selector(maskViewBackgroundColor)),
                                                                                                      NSStringFromSelector(@selector(borderColor)),
                                                                                                      NSStringFromSelector(@selector(arrowImage)),],
                                       NSStringFromClass(QMUIPopupMenuButtonItem.class):            @[NSStringFromSelector(@selector(highlightedBackgroundColor)),],
                                       NSStringFromClass(QMUIPopupMenuView.class):                  @[NSStringFromSelector(@selector(itemSeparatorColor)),
                                                                                                      NSStringFromSelector(@selector(sectionSeparatorColor)),
                                                                                                      NSStringFromSelector(@selector(itemTitleColor))],
                                       NSStringFromClass(QMUITextField.class):                      @[NSStringFromSelector(@selector(placeholderColor)),],
                                       NSStringFromClass(QMUITextView.class):                       @[NSStringFromSelector(@selector(placeholderColor)),],
                                       NSStringFromClass(QMUIToastBackgroundView.class):            @[NSStringFromSelector(@selector(styleColor)),],
                                       
                                       // ????????? class ?????????????????? UIView (QMUITheme) ?????? setNeedsDisplay???????????????????????? setter
//                                       NSStringFromClass(UILabel.class):                            @[NSStringFromSelector(@selector(textColor)),
//                                                                                                      NSStringFromSelector(@selector(shadowColor)),
//                                                                                                      NSStringFromSelector(@selector(highlightedTextColor)),],
//                                       NSStringFromClass(UITextView.class):                         @[NSStringFromSelector(@selector(attributedText)),],

                                       };
                }
                [classRegisters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull classString, NSArray<NSString *> * _Nonnull getters, BOOL * _Nonnull stop) {
                    if ([selfObject isKindOfClass:NSClassFromString(classString)]) {
                        [selfObject qmui_registerThemeColorProperties:getters];
                    }
                }];
            });
            return originReturnValue;
        });
    });
}

+ (void)registerToClass:(Class)class byBlock:(void (^)(UIView *view))block withView:(UIView *)view {
    if ([view isKindOfClass:class]) {
        block(view);
    }
}

@end

@implementation UIView (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // iOS 12 ????????????-[UIView setTintColor:] ?????????????????????????????? tintColor ???????????? tintColor ?????????????????????????????? tintColorDidChange??????????????? dynamic color ??????????????????????????????????????? dynamic color ?????????????????????????????? rawColor ??????????????????????????????????????????????????????????????? copy ??????????????????????????????????????????
        // 2022-7-20 ???????????? iOS 13-15???UIImageView???UIButton??????????????? theme ??????tintColor ??? copy ???????????????????????????????????? Dark Mode ??????????????? setTintColor:??????????????? copy ????????????????????????????????????????????? iOS ?????????????????? copy
        // https://github.com/Tencent/QMUI_iOS/issues/1418
        OverrideImplementation([UIView class], @selector(setTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIView *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.tintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
    });
}

@end

@implementation UISwitch (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // ??????????????? iOS 13 ???????????? copy ???????????????????????????????????????????????? UISwitch ?????? off ????????????????????????????????? onTintColor ?????????????????????????????????????????? on ???????????????????????? onTintColor ???????????????????????? onTintColor?????????????????????????????????
        OverrideImplementation([UISwitch class], @selector(setOnTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISwitch *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.onTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
        
        OverrideImplementation([UISwitch class], @selector(setThumbTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISwitch *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.thumbTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
    });
}


@end

@implementation UISlider (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OverrideImplementation([UISlider class], @selector(setMinimumTrackTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISlider *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.minimumTrackTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
        
        OverrideImplementation([UISlider class], @selector(setMaximumTrackTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISlider *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.maximumTrackTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
        
        OverrideImplementation([UISlider class], @selector(setThumbTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISlider *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.thumbTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
    });
}

@end

@implementation UIProgressView (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OverrideImplementation([UIProgressView class], @selector(setProgressTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIProgressView *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.progressTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
        
        OverrideImplementation([UIProgressView class], @selector(setTrackTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIProgressView *selfObject, UIColor *tintColor) {
                
                if (tintColor.qmui_isQMUIDynamicColor && tintColor == selfObject.trackTintColor) tintColor = tintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, tintColor);
            };
        });
    });
}

@end

@implementation UITabBarItem (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // UITabBarItem.image ???????????????????????? image????????? QMUIThemeImage????????? selectedImage ???????????? rawImage???????????????????????? QMUIThemeImage ????????? selectedImage ????????????????????? selectedImage ????????????????????? UITabBarItem ??????????????????????????????????????? rawImage?????????????????????????????? image ????????????
        // https://github.com/Tencent/QMUI_iOS/issues/1122
        OverrideImplementation([UITabBarItem class], @selector(setSelectedImage:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UITabBarItem *selfObject, UIImage *selectedImage) {
                
                // ?????????????????????????????? super????????? setter ??? super ???????????? getter?????????????????????????????????????????? getter ???????????? boundObject ????????????
                // https://github.com/Tencent/QMUI_iOS/issues/1218
                [selfObject qmui_bindObject:selectedImage.qmui_isDynamicImage ? selectedImage : nil forKey:@"UITabBarItem(QMUIThemeCompatibility).selectedImage"];
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIImage *);
                originSelectorIMP = (void (*)(id, SEL, UIImage *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, selectedImage);
            };
        });
        
        OverrideImplementation([UITabBarItem class], @selector(selectedImage), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^UIImage *(UITabBarItem *selfObject) {
                
                // call super
                UIImage * (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (UIImage * (*)(id, SEL))originalIMPProvider();
                UIImage *result = originSelectorIMP(selfObject, originCMD);
                
                UIImage *selectedImage = [selfObject qmui_getBoundObjectForKey:@"UITabBarItem(QMUIThemeCompatibility).selectedImage"];
                if (selectedImage) {
                    return selectedImage;
                }
                
                return result;
            };
        });
    });
}

@end

@implementation UIVisualEffectView (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OverrideImplementation([UIVisualEffectView class], @selector(setEffect:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIVisualEffectView *selfObject, UIVisualEffect *effect) {
                
                if (effect.qmui_isDynamicEffect && effect == selfObject.effect) effect = effect.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIVisualEffect *);
                originSelectorIMP = (void (*)(id, SEL, UIVisualEffect *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, effect);
            };
        });
    });
}

@end

@interface CALayer ()

@property(nonatomic, strong) UIColor *qcl_originalBackgroundColor;
@property(nonatomic, strong) UIColor *qcl_originalBorderColor;
@property(nonatomic, strong) UIColor *qcl_originalShadowColor;

@end

@implementation CALayer (QMUIThemeCompatibility)

QMUISynthesizeIdStrongProperty(qcl_originalBackgroundColor, setQcl_originalBackgroundColor)
QMUISynthesizeIdStrongProperty(qcl_originalBorderColor, setQcl_originalBorderColor)
QMUISynthesizeIdStrongProperty(qcl_originalShadowColor, setQcl_originalShadowColor)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        OverrideImplementation([CALayer class], @selector(setBackgroundColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(CALayer *selfObject, CGColorRef color) {

                // ?????????????????? CGColor ?????????????????????
                // iOS 13 ??? UIDynamicProviderColor????????? QMUIThemeColor ????????? CGColor ???????????????????????? CGColorRef ???????????????????????? color ???????????????????????? property ?????????????????????????????????
                UIColor *originalColor = [(__bridge id)(color) qmui_getBoundObjectForKey:QMUICGColorOriginalColorBindKey];
                selfObject.qcl_originalBackgroundColor = originalColor;

                // call super
                void (*originSelectorIMP)(id, SEL, CGColorRef);
                originSelectorIMP = (void (*)(id, SEL, CGColorRef))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, color);
            };
        });
        
        OverrideImplementation([CALayer class], @selector(setBorderColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(CALayer *selfObject, CGColorRef color) {
                
                UIColor *originalColor = [(__bridge id)(color) qmui_getBoundObjectForKey:QMUICGColorOriginalColorBindKey];
                selfObject.qcl_originalBorderColor = originalColor;
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGColorRef);
                originSelectorIMP = (void (*)(id, SEL, CGColorRef))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, color);
            };
        });
        
        OverrideImplementation([CALayer class], @selector(setShadowColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(CALayer *selfObject, CGColorRef color) {
                
                UIColor *originalColor = [(__bridge id)(color) qmui_getBoundObjectForKey:QMUICGColorOriginalColorBindKey];
                selfObject.qcl_originalShadowColor = originalColor;
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGColorRef);
                originSelectorIMP = (void (*)(id, SEL, CGColorRef))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, color);
            };
        });
        
        // iOS 13 ??????????????????????????????????????????????????????????????? view ??? layoutSubviews?????????????????????????????????????????????
        // ????????? QMUIThemeManager ?????????????????????????????? theme ?????????????????? qmui_setNeedsUpdateDynamicStyle?????????????????????
        ExtendImplementationOfVoidMethodWithoutArguments([UIView class], @selector(layoutSubviews), ^(UIView *selfObject) {
            [selfObject.layer qmui_setNeedsUpdateDynamicStyle];
        });
    });
}

/// ???????????????????????? CGColor ???????????????
- (void)qmui_setNeedsUpdateDynamicStyle {
    if (self.qcl_originalBackgroundColor) {
        UIColor *originalColor = self.qcl_originalBackgroundColor;
        self.backgroundColor = originalColor.CGColor;
    }
    if (self.qcl_originalBorderColor) {
        self.borderColor = self.qcl_originalBorderColor.CGColor;
    }
    if (self.qcl_originalShadowColor) {
        self.shadowColor = self.qcl_originalShadowColor.CGColor;
    }
    
    [self.sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!sublayer.qmui_isRootLayerOfView) {// ????????? UIView ??? rootLayer??????????????? UIView ???????????? layoutSubviews ??????????????????????????????????????????????????????????????????????????????????????? layer ?????? sublayer ??????
            [sublayer qmui_setNeedsUpdateDynamicStyle];
        }
    }];
}

@end

@interface UISearchBar ()

@property(nonatomic, readonly) NSMutableDictionary <NSString * ,NSInvocation *>*qmuiTheme_invocations;

@end

@implementation UISearchBar (QMUIThemeCompatibility)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        OverrideImplementation([UISearchBar class], @selector(setSearchFieldBackgroundImage:forState:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            
            NSMethodSignature *methodSignature = [originClass instanceMethodSignatureForSelector:originCMD];
            
            return ^(UISearchBar *selfObject, UIImage *image, UIControlState state) {
                
                void (*originSelectorIMP)(id, SEL, UIImage *, UIControlState);
                originSelectorIMP = (void (*)(id, SEL, UIImage *, UIControlState))originalIMPProvider();
                
                UIImage *previousImage = [selfObject searchFieldBackgroundImageForState:state];
                if (previousImage.qmui_isDynamicImage || image.qmui_isDynamicImage) {
                    // setSearchFieldBackgroundImage:forState: ?????????????????????:
                    // ???????????? image ?????????????????? layout ???????????? -[UITextFieldBorderView setImage:] ?????????????????????????????????
                    // if (UITextFieldBorderView._image == image) return
                    // ?????? QMUIDynamicImage ??????????????????????????????????????????????????????????????????????????????????????? image?????????????????? layoutIfNeeded ?????? -[UITextFieldBorderView setImage:] ?????? UITextFieldBorderView ????????? image ?????????????????????????????????????????????
                    originSelectorIMP(selfObject, originCMD, UIImage.new, state);
                    [selfObject.searchTextField setNeedsLayout];
                    [selfObject.searchTextField layoutIfNeeded];
                }
                originSelectorIMP(selfObject, originCMD, image, state);
                
                NSInvocation *invocation = nil;
                NSString *invocationActionKey = [NSString stringWithFormat:@"%@-%zd", NSStringFromSelector(originCMD), state];
                if (image.qmui_isDynamicImage) {
                    invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                    [invocation setSelector:originCMD];
                    [invocation setArgument:&image atIndex:2];
                    [invocation setArgument:&state atIndex:3];
                    [invocation retainArguments];
                }
                selfObject.qmuiTheme_invocations[invocationActionKey] = invocation;
            };
        });
        
        OverrideImplementation([UISearchBar class], @selector(setBarTintColor:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISearchBar *selfObject, UIColor *barTintColor) {
                
                if (barTintColor.qmui_isQMUIDynamicColor && barTintColor == selfObject.barTintColor) barTintColor = barTintColor.copy;
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *);
                originSelectorIMP = (void (*)(id, SEL, UIColor *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, barTintColor);
            };
        });
    });
}

- (void)_qmui_themeDidChangeByManager:(QMUIThemeManager *)manager identifier:(__kindof NSObject<NSCopying> *)identifier theme:(__kindof NSObject *)theme shouldEnumeratorSubviews:(BOOL)shouldEnumeratorSubviews {
    [super _qmui_themeDidChangeByManager:manager identifier:identifier theme:theme shouldEnumeratorSubviews:shouldEnumeratorSubviews];
    [self qmuiTheme_performUpdateInvocations];
}

- (void)qmuiTheme_performUpdateInvocations {
    [[self.qmuiTheme_invocations allValues] enumerateObjectsUsingBlock:^(NSInvocation * _Nonnull invocation, NSUInteger idx, BOOL * _Nonnull stop) {
        [invocation setTarget:self];
        [invocation invoke];
    }];
}


- (NSMutableDictionary *)qmuiTheme_invocations {
    NSMutableDictionary *qmuiTheme_invocations = objc_getAssociatedObject(self, _cmd);
    if (!qmuiTheme_invocations) {
        qmuiTheme_invocations = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, qmuiTheme_invocations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return qmuiTheme_invocations;
}

@end
