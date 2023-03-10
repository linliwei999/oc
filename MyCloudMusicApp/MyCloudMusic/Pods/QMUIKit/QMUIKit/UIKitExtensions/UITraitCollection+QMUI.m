/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */
//
//  UITraitCollection+QMUI.m
//  QMUIKit
//
//  Created by ziezheng on 2019/7/19.
//

#import "UITraitCollection+QMUI.h"
#import "QMUICore.h"
#import <dlfcn.h>

@implementation UITraitCollection (QMUI)

static NSHashTable *_eventObservers;
static NSString * const kQMUIUserInterfaceStyleWillChangeSelectorsKey = @"qmui_userInterfaceStyleWillChangeObserver";

+ (void)qmui_addUserInterfaceStyleWillChangeObserver:(id)observer selector:(SEL)aSelector {
    @synchronized (self) {
        [UITraitCollection _qmui_overrideTraitCollectionMethodIfNeeded];
        if (!_eventObservers) {
            _eventObservers = [NSHashTable weakObjectsHashTable];
        }
        NSMutableSet *selectors = [observer qmui_getBoundObjectForKey:kQMUIUserInterfaceStyleWillChangeSelectorsKey];
        if (!selectors) {
            selectors = [NSMutableSet set];
            [observer qmui_bindObject:selectors forKey:kQMUIUserInterfaceStyleWillChangeSelectorsKey];
        }
        [selectors addObject:NSStringFromSelector(aSelector)];
        [_eventObservers addObject:observer];
    }
}

+ (void)_qmui_notifyUserInterfaceStyleWillChangeEvents:(UITraitCollection *)traitCollection {
    NSHashTable *eventObservers = [_eventObservers copy];
    for (id observer in eventObservers) {
        NSMutableSet *selectors = [observer qmui_getBoundObjectForKey:kQMUIUserInterfaceStyleWillChangeSelectorsKey];
        for (NSString *selectorString in selectors) {
            SEL selector = NSSelectorFromString(selectorString);
            if ([observer respondsToSelector:selector]) {
                NSMethodSignature *methodSignature = [observer methodSignatureForSelector:selector];
                NSUInteger numberOfArguments = [methodSignature numberOfArguments] - 2; // ?????? self cmd ?????????????????????????????????
                QMUIAssert(numberOfArguments <= 1, @"UITraitCollection (QMUI)", @"observer ??? selector ???????????? 1 ???");
                BeginIgnorePerformSelectorLeaksWarning
                if (numberOfArguments == 0) {
                    [observer performSelector:selector];
                } else if (numberOfArguments == 1) {
                    [observer performSelector:selector withObject:traitCollection];
                }
                EndIgnorePerformSelectorLeaksWarning
            }
        }
    }
}

+ (void)_qmui_overrideTraitCollectionMethodIfNeeded {
    [QMUIHelper executeBlock:^{
        static UIUserInterfaceStyle qmui_lastNotifiedUserInterfaceStyle;
        qmui_lastNotifiedUserInterfaceStyle = [UITraitCollection currentTraitCollection].userInterfaceStyle;
        
        // - (void) _willTransitionToTraitCollection:(id)arg1 withTransitionCoordinator:(id)arg2; (0x7fff24711d49)
        OverrideImplementation([UIWindow class], NSSelectorFromString([NSString qmui_stringByConcat:@"_", @"willTransitionToTraitCollection:", @"withTransitionCoordinator:", nil]), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIWindow *selfObject, UITraitCollection *traitCollection, id <UIViewControllerTransitionCoordinator> coordinator) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, UITraitCollection *, id <UIViewControllerTransitionCoordinator>);
                originSelectorIMP = (void (*)(id, SEL, UITraitCollection *, id <UIViewControllerTransitionCoordinator>))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, traitCollection, coordinator);
                
                BOOL snapshotFinishedOnBackground = traitCollection.userInterfaceLevel == UIUserInterfaceLevelElevated && UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
                // ??????????????????????????????????????????????????? style ??????????????? iOS 13.0 iPad ??????????????????????????????????????????????????? style????????????????????????????????????????????????????????????
                if (selfObject.windowScene && !snapshotFinishedOnBackground) {
                    UIWindow *firstValidatedWindow = nil;
                    
                    if ([NSStringFromClass(selfObject.class) containsString:@"_UIWindowSceneUserInterfaceStyle"]) { // _UIWindowSceneUserInterfaceStyleAnimationSnapshotWindow
                        firstValidatedWindow = selfObject;
                    } else {
                        // ????????????????????????????????????????????? window ??? traitCollection???????????????????????????????????? window
                        NSPointerArray *windows = [[selfObject windowScene] valueForKeyPath:@"_contextBinder._attachedBindables"];
                        for (NSUInteger i = 0, count = windows.count; i < count; i++) {
                            UIWindow *window = [windows pointerAtIndex:i];
                            // ????????? UIWindow ?????????????????????????????????????????? windows ???????????????????????? nil ????????????????????????????????????????????? App ????????????????????????????????????????????? style
                            if (!window) {
                                continue;;
                            }
                            
                            // ?????? Keyboard ???????????? keyboardAppearance ????????? userInterfaceStyle ??? Dark/Light????????????????????????????????????????????????
                            if ([window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")] || [window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) {
                                continue;
                            }
                            if (window.overrideUserInterfaceStyle != UIUserInterfaceStyleUnspecified) {
                                // ????????????????????????????????????????????? UserInterfaceStyle??????????????? overrideUserInterfaceStyle ???????????????
                                // ??????????????? window.overrideUserInterfaceStyle ??????????????? UIUserInterfaceStyleUnspecified ???????????????????????????????????????
                                continue;
                            }
                            firstValidatedWindow = window;
                            break;
                        }
                    }
                    
                    if (selfObject == firstValidatedWindow) {
                        if (qmui_lastNotifiedUserInterfaceStyle != traitCollection.userInterfaceStyle) {
                            qmui_lastNotifiedUserInterfaceStyle = traitCollection.userInterfaceStyle;
                            [self _qmui_notifyUserInterfaceStyleWillChangeEvents:traitCollection];
                        }
                    }
                }
            };
        });
    } oncePerIdentifier:@"UITraitCollection addUserInterfaceStyleWillChangeObserver"];
}

@end
