/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UIButton+QMUI.m
//  qmui
//
//  Created by QMUI Team on 15/7/20.
//

#import "UIButton+QMUI.h"
#import "QMUICore.h"
#import "UIImage+QMUI.h"

@interface UIButton ()

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSDictionary<NSAttributedStringKey, id> *> *qbt_titleAttributes;
@property(nonatomic, strong) NSMutableSet<NSNumber *> *qbt_statesWithTitle;

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, UIColor *> *qbt_imageTintColors;
@property(nonatomic, strong) NSMutableSet<NSNumber *> *qbt_statesWithImageTintColor;

@end

@implementation UIButton (QMUI)

QMUISynthesizeIdStrongProperty(qbt_titleAttributes, setQbt_titleAttributes)
QMUISynthesizeIdStrongProperty(qbt_statesWithTitle, setQbt_statesWithTitle)
QMUISynthesizeIdStrongProperty(qbt_imageTintColors, setQbt_imageTintColors)
QMUISynthesizeIdStrongProperty(qbt_statesWithImageTintColor, setQbt_statesWithImageTintColor)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        OverrideImplementation([UIButton class], @selector(setTitle:forState:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIButton *selfObject, NSString *title, UIControlState state) {
                
                if (title.length) {
                    if (!selfObject.qbt_statesWithTitle) {
                        selfObject.qbt_statesWithTitle = [[NSMutableSet alloc] init];
                    }
                    if (state == UIControlStateNormal) {
                        [selfObject.qbt_statesWithTitle addObject:@(state)];
                    } else {
                        NSString *normalTitle = [selfObject titleForState:UIControlStateNormal] ?: [selfObject attributedTitleForState:UIControlStateNormal].string;
                        if (![title isEqualToString:normalTitle]) {
                            [selfObject.qbt_statesWithTitle addObject:@(state)];
                        } else {
                            [selfObject.qbt_statesWithTitle removeObject:@(state)];
                        }
                    }
                } else {
                    [selfObject.qbt_statesWithTitle removeObject:@(state)];
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, NSString *, UIControlState);
                originSelectorIMP = (void (*)(id, SEL, NSString *, UIControlState))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, title, state);
                
                [selfObject qbt_syncTitleByStates];
            };
        });
        
        ExtendImplementationOfVoidMethodWithoutArguments([UIButton class], @selector(layoutSubviews), ^(UIButton *selfObject) {
            // ???????????? iOS 13 ????????????????????????Bold Text????????? UIButton Title ??????????????? https://github.com/Tencent/QMUI_iOS/issues/620
            if (UIAccessibilityIsBoldTextEnabled()) {
                [selfObject.titleLabel sizeToFit];
            }
        });
    });
}

- (instancetype)qmui_initWithImage:(UIImage *)image title:(NSString *)title {
    // ??? init ??????????????????????????? self ????????????????????????????????????????????? self = [self init]
    BeginIgnoreClangWarning(-Wunused-value)
    [self init];
    EndIgnoreClangWarning
    
    [self setImage:image forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateNormal];
    return self;
}

- (void)qmui_calculateHeightAfterSetAppearance {
    [self setTitle:@"???" forState:UIControlStateNormal];
    [self sizeToFit];
    [self setTitle:nil forState:UIControlStateNormal];
}

#pragma mark - TitleAttributes

- (void)qmui_setTitleAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes forState:(UIControlState)state {
    if (!attributes && self.qbt_titleAttributes) {
        [self.qbt_titleAttributes removeObjectForKey:@(state)];
        return;
    }
    
    [UIButton qbt_swizzleForTitleAttributesIfNeeded];
    
    if (!self.qbt_titleAttributes) {
        self.qbt_titleAttributes = [[NSMutableDictionary alloc] init];
    }
    
    // ??? Normal ????????????????????? state
    if (state != UIControlStateNormal && self.qbt_titleAttributes[@(UIControlStateNormal)]) {
        NSMutableDictionary<NSAttributedStringKey, id> *temp = attributes.mutableCopy;
        NSDictionary<NSAttributedStringKey, id> *normalAttributes = self.qbt_titleAttributes[@(UIControlStateNormal)];
        for (NSAttributedStringKey key in normalAttributes.allKeys) {
            if (!temp[key]) {
                temp[key] = normalAttributes[key];
            }
        }
        attributes = temp.copy;
    }
    
    self.qbt_titleAttributes[@(state)] = attributes;
    
    // ??????????????????????????? attributes ?????????????????? setTitle:forState: ???????????????????????????????????? attributes
    [self qbt_syncTitleByStates];
    
    // ?????????????????????????????????bug??????????????????? UIControlStateHighlighted????????? normal ??????????????? state?????????????????? NSFont/NSKern/NSUnderlineAttributeName ????????? attributedString ??????????????? setTitle:forState: ??? UIControlStateNormal ?????????????????? string ??????????????? highlighted ????????? normal ????????????font ????????????????????????????????? highlighted ????????????
    // ??????????????????????????????????????????????????? normal ????????? state ???????????? qbt_titleAttributes ???????????????????????? attributedString?????? normal ??????????????? attributedString
    if (self.qbt_titleAttributes.count && !self.qbt_titleAttributes[@(UIControlStateNormal)]) {
        [self qmui_setTitleAttributes:@{} forState:UIControlStateNormal];
    }
}

// ?????? normal ?????? attributedTitle?????????????????? state ???????????? attributedTitle??????????????????????????????
- (void)qbt_syncTitleByStates {
    if (!self.qbt_titleAttributes.count) return;
    for (NSNumber *stateValue in self.qbt_statesWithTitle) {
        UIControlState state = stateValue.unsignedIntegerValue;
        NSString *title = [self titleForState:state];
        NSDictionary<NSAttributedStringKey, id> *attributes = self.qbt_titleAttributes[stateValue] ?: self.qbt_titleAttributes[@(UIControlStateNormal)];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        string = [UIButton qbt_attributedStringByRemovingLastKern:string];
        [self setAttributedTitle:string forState:state];
    }
}

+ (void)qbt_swizzleForTitleAttributesIfNeeded {
    [QMUIHelper executeBlock:^{
        // ?????????????????????????????? state ????????????????????????????????????????????????
        OverrideImplementation([UIButton class], @selector(setTitleColor:forState:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIButton *selfObject, UIColor *color, UIControlState state) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIColor *, UIControlState);
                originSelectorIMP = (void (*)(id, SEL, UIColor *, UIControlState))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, color, state);
                
                NSDictionary *attributes = selfObject.qbt_titleAttributes[@(state)];
                if (attributes) {
                    NSMutableDictionary<NSAttributedStringKey, id> *newAttributes = attributes.mutableCopy;
                    newAttributes[NSForegroundColorAttributeName] = color;
                    [selfObject qmui_setTitleAttributes:newAttributes.copy forState:state];
                }
            };
        });
    } oncePerIdentifier:@"UIButton (QMUI) titleAttributes"];
}

// ???????????????????????? kern ???????????????????????????????????????????????????
+ (NSAttributedString *)qbt_attributedStringByRemovingLastKern:(NSAttributedString *)string {
    if (!string.length) {
        return string;
    }
    NSMutableAttributedString *attributedString = string.mutableCopy;
    [attributedString removeAttribute:NSKernAttributeName range:NSMakeRange(string.length - 1, 1)];
    return attributedString.copy;
}

#pragma mark - ImageTintColor

- (void)qmui_setImageTintColor:(UIColor *)color forState:(UIControlState)state {
    if (!color && self.qbt_imageTintColors) {
        [self.qbt_imageTintColors removeObjectForKey:@(state)];
        return;
    }
    
    [UIButton qbt_swizzleForImageTintColorIfNeeded];
    
    if (!self.qbt_imageTintColors) {
        self.qbt_imageTintColors = [[NSMutableDictionary alloc] init];
    }
    self.qbt_imageTintColors[@(state)] = color;
    
    UIImage *stateImage = [self imageForState:state];
    if (!stateImage) return;
    stateImage = [[stateImage qmui_imageWithTintColor:color] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self setImage:stateImage forState:state];
}

+ (void)qbt_swizzleForImageTintColorIfNeeded {
    [QMUIHelper executeBlock:^{
        OverrideImplementation([UIButton class], @selector(setImage:forState:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIButton *selfObject, UIImage *image, UIControlState state) {
                
                BOOL isFirstSetImage = image && ![selfObject imageForState:UIControlStateNormal];
                
                UIColor *imageTintColor = selfObject.qbt_imageTintColors[@(state)];
                if (imageTintColor) {
                    image = [[image qmui_imageWithTintColor:imageTintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIImage *, UIControlState);
                originSelectorIMP = (void (*)(id, SEL, UIImage *, UIControlState))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, image, state);
                
                if (isFirstSetImage) {
                    [selfObject.qbt_imageTintColors enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UIColor * _Nonnull color, BOOL * _Nonnull stop) {
                        UIControlState s = key.unsignedIntegerValue;
                        if (s != state) {// ???????????????
                            UIImage *stateImage = [selfObject imageForState:s];
                            if (stateImage) {
                                stateImage = [[stateImage qmui_imageWithTintColor:color] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                                [selfObject setImage:stateImage forState:s];
                            }
                        }
                    }];
                }
            };
        });
    } oncePerIdentifier:@"UIButton (QMUI) titleAttributes"];
}

@end
