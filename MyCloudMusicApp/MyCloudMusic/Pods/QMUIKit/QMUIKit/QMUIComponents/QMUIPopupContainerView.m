/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  QMUIPopupContainerView.m
//  qmui
//
//  Created by QMUI Team on 15/12/17.
//

#import "QMUIPopupContainerView.h"
#import "QMUICore.h"
#import "QMUICommonViewController.h"
#import "UIViewController+QMUI.h"
#import "QMUILog.h"
#import "UIView+QMUI.h"
#import "UIWindow+QMUI.h"
#import "UIBarItem+QMUI.h"
#import "QMUIAppearance.h"
#import "CALayer+QMUI.h"
#import "NSShadow+QMUI.h"

@interface QMUIPopupContainerViewWindow : UIWindow

@end

@interface QMUIPopContainerViewController : QMUICommonViewController

@end

@interface QMUIPopContainerMaskControl : UIControl

@property(nonatomic, weak) QMUIPopupContainerView *popupContainerView;
@end

@interface QMUIPopupContainerView () {
    UIImageView                     *_imageView;
    UILabel                         *_textLabel;
    
    CALayer                         *_backgroundViewMaskLayer;
    CAShapeLayer                    *_copiedBackgroundLayer;
    CALayer                         *_copiedArrowImageLayer;
}

@property(nonatomic, strong) QMUIPopupContainerViewWindow *popupWindow;
@property(nonatomic, weak) UIWindow *previousKeyWindow;
@property(nonatomic, assign) BOOL hidesByUserTap;
@end

@implementation QMUIPopupContainerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)dealloc {
    _sourceView.qmui_frameDidChangeBlock = nil;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = UIFontMake(12);
        _textLabel.textColor = UIColorBlack;
        _textLabel.numberOfLines = 0;
        [self.contentView addSubview:_textLabel];
    }
    return _textLabel;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if (result == self.contentView) {
        return self;
    }
    return result;
}

- (void)setBackgroundView:(UIView *)backgroundView {
    if (_backgroundView && !backgroundView) {
        [_backgroundView removeFromSuperview];
    }
    _backgroundView = backgroundView;
    if (backgroundView) {
        [self insertSubview:backgroundView atIndex:0];
        // backgroundView ???????????? _backgroundLayer???_arrowImageView ???????????????????????????????????????????????????????????? backgroundView ?????????????????????
        [self sendSubviewToBack:_arrowImageView];
        [self.layer qmui_sendSublayerToBack:_backgroundLayer];
        if (!_backgroundViewMaskLayer) {
            _copiedBackgroundLayer = [CAShapeLayer layer];
            [_copiedBackgroundLayer qmui_removeDefaultAnimations];
            _copiedBackgroundLayer.fillColor = UIColor.blackColor.CGColor;// ?????? layer ????????? mask ???????????????????????????????????????????????????????????????????????? mask ??????
            
            _copiedArrowImageLayer = [CALayer layer];
            [_copiedArrowImageLayer qmui_removeDefaultAnimations];
            
            _backgroundViewMaskLayer = [CALayer layer];
            [_backgroundViewMaskLayer qmui_removeDefaultAnimations];
            [_backgroundViewMaskLayer addSublayer:_copiedBackgroundLayer];
            [_backgroundViewMaskLayer addSublayer:_copiedArrowImageLayer];
        }
        backgroundView.layer.mask = _backgroundViewMaskLayer;
    }
    // ?????? backgroundView ???????????????????????????????????? backgroundView ??????????????????
    _arrowImageView.hidden = backgroundView || !self.arrowImage;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    _backgroundLayer.fillColor = _backgroundColor.CGColor;
    _arrowImageView.tintColor = backgroundColor;
}

- (void)setMaskViewBackgroundColor:(UIColor *)maskViewBackgroundColor {
    _maskViewBackgroundColor = maskViewBackgroundColor;
    if (self.popupWindow) {
        self.popupWindow.rootViewController.view.backgroundColor = maskViewBackgroundColor;
    }
}

- (void)setShadow:(NSShadow *)shadow {
    _shadow = shadow;
    _backgroundLayer.qmui_shadow = shadow;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    _backgroundLayer.strokeColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    _backgroundLayer.lineWidth = _borderWidth;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (self.highlightedBackgroundColor) {
        UIColor *color = highlighted ? self.highlightedBackgroundColor : self.backgroundColor;
        _backgroundLayer.fillColor = color.CGColor;
        _arrowImageView.tintColor = color;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize contentLimitSize = [self contentSizeInSize:size];
    CGSize contentSize = CGSizeZero;
    if (self.contentViewSizeThatFitsBlock) {
        contentSize = self.contentViewSizeThatFitsBlock(contentLimitSize);
    } else {
        contentSize = [self sizeThatFitsInContentView:contentLimitSize];
    }
    CGSize resultSize = [self sizeWithContentSize:contentSize sizeThatFits:size];
    return resultSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isUsingArrowImage = !!self.arrowImage;
    CGAffineTransform arrowImageTransform = CGAffineTransformIdentity;
    CGPoint arrowImagePosition = CGPointZero;
    
    CGSize arrowSize = self.arrowSizeAuto;
    CGRect roundedRect = CGRectMake(self.borderWidth / 2.0 + (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight ? arrowSize.width : 0),
                                    self.borderWidth / 2.0 + (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow ? arrowSize.height : 0),
                                    CGRectGetWidth(self.bounds) - self.borderWidth - self.arrowSpacingInHorizontal,
                                    CGRectGetHeight(self.bounds) - self.borderWidth - self.arrowSpacingInVertical);
    CGFloat cornerRadius = self.cornerRadius;
    
    CGPoint leftTopArcCenter = CGPointMake(CGRectGetMinX(roundedRect) + cornerRadius, CGRectGetMinY(roundedRect) + cornerRadius);
    CGPoint leftBottomArcCenter = CGPointMake(leftTopArcCenter.x, CGRectGetMaxY(roundedRect) - cornerRadius);
    CGPoint rightTopArcCenter = CGPointMake(CGRectGetMaxX(roundedRect) - cornerRadius, leftTopArcCenter.y);
    CGPoint rightBottomArcCenter = CGPointMake(rightTopArcCenter.x, leftBottomArcCenter.y);
    
    // ???????????????????????????
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(leftTopArcCenter.x, CGRectGetMinY(roundedRect))];
    [path addArcWithCenter:leftTopArcCenter radius:cornerRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight) {
        // ????????????
        if (isUsingArrowImage) {
            arrowImageTransform = CGAffineTransformMakeRotation(AngleWithDegrees(90));
            arrowImagePosition = CGPointMake(arrowSize.width / 2, _arrowMinY + arrowSize.height / 2);
        } else {
            [path addLineToPoint:CGPointMake(CGRectGetMinX(roundedRect), _arrowMinY)];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(roundedRect) - arrowSize.width, _arrowMinY + arrowSize.height / 2)];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(roundedRect), _arrowMinY + arrowSize.height)];
        }
    }
    
    [path addLineToPoint:CGPointMake(CGRectGetMinX(roundedRect), leftBottomArcCenter.y)];
    [path addArcWithCenter:leftBottomArcCenter radius:cornerRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
    
    if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionAbove) {
        // ????????????
        if (isUsingArrowImage) {
            arrowImagePosition = CGPointMake(_arrowMinX + arrowSize.width / 2, CGRectGetHeight(self.bounds) - arrowSize.height / 2);
        } else {
            [path addLineToPoint:CGPointMake(_arrowMinX, CGRectGetMaxY(roundedRect))];
            [path addLineToPoint:CGPointMake(_arrowMinX + arrowSize.width / 2, CGRectGetMaxY(roundedRect) + arrowSize.height)];
            [path addLineToPoint:CGPointMake(_arrowMinX + arrowSize.width, CGRectGetMaxY(roundedRect))];
        }
    }
    
    [path addLineToPoint:CGPointMake(rightBottomArcCenter.x, CGRectGetMaxY(roundedRect))];
    [path addArcWithCenter:rightBottomArcCenter radius:cornerRadius startAngle:M_PI * 0.5 endAngle:0.0 clockwise:NO];
    
    if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionLeft) {
        // ????????????
        if (isUsingArrowImage) {
            arrowImageTransform = CGAffineTransformMakeRotation(AngleWithDegrees(-90));
            arrowImagePosition = CGPointMake(CGRectGetWidth(self.bounds) - arrowSize.width / 2, _arrowMinY + arrowSize.height / 2);
        } else {
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(roundedRect), _arrowMinY + arrowSize.height)];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(roundedRect) + arrowSize.width, _arrowMinY + arrowSize.height / 2)];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(roundedRect), _arrowMinY)];
        }
    }
    
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(roundedRect), rightTopArcCenter.y)];
    [path addArcWithCenter:rightTopArcCenter radius:cornerRadius startAngle:0.0 endAngle:M_PI * 1.5 clockwise:NO];
    
    if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow) {
        // ????????????
        if (isUsingArrowImage) {
            arrowImageTransform = CGAffineTransformMakeRotation(AngleWithDegrees(-180));
            arrowImagePosition = CGPointMake(_arrowMinX + arrowSize.width / 2, arrowSize.height / 2);
        } else {
            [path addLineToPoint:CGPointMake(_arrowMinX + arrowSize.width, CGRectGetMinY(roundedRect))];
            [path addLineToPoint:CGPointMake(_arrowMinX + arrowSize.width / 2, CGRectGetMinY(roundedRect) - arrowSize.height)];
            [path addLineToPoint:CGPointMake(_arrowMinX, CGRectGetMinY(roundedRect))];
        }
    }
    [path closePath];
    
    _backgroundLayer.path = path.CGPath;
    _backgroundLayer.shadowPath = path.CGPath;
    _backgroundLayer.frame = self.bounds;
    
    if (isUsingArrowImage) {
        _arrowImageView.transform = arrowImageTransform;
        _arrowImageView.center = arrowImagePosition;
    }
    
    if (self.backgroundView) {
        self.backgroundView.frame = self.bounds;
        _backgroundViewMaskLayer.frame = self.bounds;
        
        _copiedBackgroundLayer.path = _backgroundLayer.path;
        _copiedBackgroundLayer.frame = _backgroundLayer.frame;
        
        _copiedArrowImageLayer.bounds = _arrowImageView.bounds;
        _copiedArrowImageLayer.affineTransform = arrowImageTransform;
        _copiedArrowImageLayer.position = arrowImagePosition;
        _copiedArrowImageLayer.contents = (id)_arrowImageView.image.CGImage;
        _copiedArrowImageLayer.contentsScale = _arrowImageView.image.scale;
    }
    
    [self layoutDefaultSubviews];
}

- (void)layoutDefaultSubviews {
    self.contentView.frame = CGRectMake(
                                        self.borderWidth + self.contentEdgeInsets.left + (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight ? self.arrowSizeAuto.width : 0),
                                        self.borderWidth + self.contentEdgeInsets.top + (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow ? self.arrowSizeAuto.height : 0),
                                        CGRectGetWidth(self.bounds) - self.borderWidth * 2 - UIEdgeInsetsGetHorizontalValue(self.contentEdgeInsets) - self.arrowSpacingInHorizontal,
                                        CGRectGetHeight(self.bounds) - self.borderWidth * 2 - UIEdgeInsetsGetVerticalValue(self.contentEdgeInsets) - self.arrowSpacingInVertical);
    // contentView???????????????????????????path????????????????????????????????????????????????self.contentEdgeInsets.left???self.cornerRadius????????????????????????contentView?????????????????????
    // ??????????????????????????????contentView?????????????????????????????????????????????????????????????????????
    CGFloat contentViewCornerRadius = fabs(MIN(CGRectGetMinX(self.contentView.frame) - self.cornerRadius, 0));
    self.contentView.layer.cornerRadius = contentViewCornerRadius;
    
    BOOL isImageViewShowing = [self isSubviewShowing:_imageView];
    BOOL isTextLabelShowing = [self isSubviewShowing:_textLabel];
    if (isImageViewShowing) {
        [_imageView sizeToFit];
        _imageView.frame = CGRectSetX(_imageView.frame, self.imageEdgeInsets.left);//, self.imageEdgeInsets.top + (self.contentMode == UIViewContentModeTop ? 0 : CGFloatGetCenter(CGRectGetHeight(self.contentView.bounds), CGRectGetHeight(_imageView.frame))));
        if (self.contentMode == UIViewContentModeTop) {
            _imageView.frame = CGRectSetY(_imageView.frame, self.imageEdgeInsets.top);
        } else if (self.contentMode == UIViewContentModeBottom) {
            _imageView.frame = CGRectSetY(_imageView.frame, CGRectGetHeight(self.contentView.bounds) - self.imageEdgeInsets.bottom - CGRectGetHeight(_imageView.frame));
        } else {
            _imageView.frame = CGRectSetY(_imageView.frame, self.imageEdgeInsets.top + CGFloatGetCenter(CGRectGetHeight(self.contentView.bounds), CGRectGetHeight(_imageView.frame)));
        }
    }
    if (isTextLabelShowing) {
        CGFloat textLabelMinX = (isImageViewShowing ? ceil(CGRectGetMaxX(_imageView.frame) + self.imageEdgeInsets.right) : 0) + self.textEdgeInsets.left;
        CGSize textLabelLimitSize = CGSizeMake(ceil(CGRectGetWidth(self.contentView.bounds) - textLabelMinX), ceil(CGRectGetHeight(self.contentView.bounds) - self.textEdgeInsets.top - self.textEdgeInsets.bottom));
        CGSize textLabelSize = [_textLabel sizeThatFits:textLabelLimitSize];
        _textLabel.frame = CGRectMake(textLabelMinX, 0, textLabelLimitSize.width, ceil(textLabelSize.height));
        if (self.contentMode == UIViewContentModeTop) {
            _textLabel.frame = CGRectSetY(_textLabel.frame, self.textEdgeInsets.top);
        } else if (self.contentMode == UIViewContentModeBottom) {
            _textLabel.frame = CGRectSetY(_textLabel.frame, CGRectGetHeight(self.contentView.bounds) - self.textEdgeInsets.bottom - CGRectGetHeight(_textLabel.frame));
        } else {
            _textLabel.frame = CGRectSetY(_textLabel.frame, self.textEdgeInsets.top + CGFloatGetCenter(CGRectGetHeight(self.contentView.bounds), CGRectGetHeight(_textLabel.frame)));
        }
    }
}

- (void)setSourceBarItem:(__kindof UIBarItem *)sourceBarItem {
    if (_sourceBarItem && _sourceBarItem != sourceBarItem) {
        _sourceBarItem.qmui_viewLayoutDidChangeBlock = nil;
    }
    
    _sourceBarItem = sourceBarItem;
    if (!_sourceBarItem) return;
    
    __weak __typeof(self)weakSelf = self;
    // ???????????????????????? block????????????????????? popup ???????????? sourceBarItem ??????????????? block ??????????????? weakSelf ?????????????????????
    sourceBarItem.qmui_viewLayoutDidChangeBlock = ^(__kindof UIBarItem * _Nonnull item, UIView * _Nullable view) {
        if (!view.window || !weakSelf.superview) return;
        UIView *convertToView = weakSelf.popupWindow ? UIApplication.sharedApplication.delegate.window : weakSelf.superview;// ????????? window ????????????????????????????????????????????????????????? window ?????????????????????????????????????????? sourceBarItem ????????? window ?????????????????? popupWindow ???????????????iOS 11 ??????????????????????????????????????????????????????????????????????????? UIApplication window
        CGRect rect = [view qmui_convertRect:view.bounds toView:convertToView];
        weakSelf.sourceRect = rect;
    };
    if (sourceBarItem.qmui_view && sourceBarItem.qmui_viewLayoutDidChangeBlock) {
        sourceBarItem.qmui_viewLayoutDidChangeBlock(sourceBarItem, sourceBarItem.qmui_view);// update layout immediately
    }
}

- (void)setSourceView:(__kindof UIView *)sourceView {
    if (_sourceView && _sourceView != sourceView) {
        _sourceView.qmui_frameDidChangeBlock = nil;
    }
    
    _sourceView = sourceView;
    if (!_sourceView) return;
    
    __weak __typeof(self)weakSelf = self;
    sourceView.qmui_frameDidChangeBlock = ^(__kindof UIView * _Nonnull view, CGRect precedingFrame) {
        if (!view.window || !weakSelf.superview) return;
        UIView *convertToView = weakSelf.popupWindow ? UIApplication.sharedApplication.delegate.window : weakSelf.superview;// ????????? window ????????????????????????????????????????????????????????? window ?????????????????????????????????????????? sourceBarItem ????????? window ?????????????????? popupWindow ???????????????iOS 11 ??????????????????????????????????????????????????????????????????????????? UIApplication window
        CGRect rect = [view qmui_convertRect:view.bounds toView:convertToView];
        weakSelf.sourceRect = rect;
    };
    sourceView.qmui_frameDidChangeBlock(sourceView, sourceView.frame);// update layout immediately
}

- (void)setSourceRect:(CGRect)sourceRect {
    _sourceRect = sourceRect;
    if (self.isShowing) {
        [self layoutWithTargetRect:sourceRect];
    }
}

- (void)updateLayout {
    // call setter to layout immediately
    if (self.sourceBarItem) {
        self.sourceBarItem = self.sourceBarItem;
    } else if (self.sourceView) {
        self.sourceView = self.sourceView;
    } else {
        self.sourceRect = self.sourceRect;
    }
}

// ?????? targetRect ??? window ???????????? window ?????????????????????????????? subview ??????????????? superview ???????????????
- (void)layoutWithTargetRect:(CGRect)targetRect {
    UIView *superview = self.superview;
    if (!superview) {
        return;
    }
    
    _currentLayoutDirection = self.preferLayoutDirection;
    targetRect = self.popupWindow ? [self.popupWindow convertRect:targetRect toView:superview] : targetRect;
    CGRect containerRect = superview.bounds;
    
    CGSize (^sizeToFitBlock)(void) = ^CGSize(void) {
        CGSize result = CGSizeZero;
        if (self.isVerticalLayoutDirection) {
            result.width = CGRectGetWidth(containerRect) - UIEdgeInsetsGetHorizontalValue(self.safetyMarginsAvoidSafeAreaInsets);
        } else if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionLeft) {
            result.width = CGRectGetMinX(targetRect) - self.distanceBetweenSource - self.safetyMarginsAvoidSafeAreaInsets.left;
        } else if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight) {
            result.width = CGRectGetWidth(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.right - self.distanceBetweenSource - CGRectGetMaxX(targetRect);
        }
        if (self.isHorizontalLayoutDirection) {
            result.height = CGRectGetHeight(containerRect) - UIEdgeInsetsGetVerticalValue(self.safetyMarginsAvoidSafeAreaInsets);
        } else if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionAbove) {
            result.height = CGRectGetMinY(targetRect) - self.distanceBetweenSource - self.safetyMarginsAvoidSafeAreaInsets.top;
        } else if (self.currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow) {
            result.height = CGRectGetHeight(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.bottom - self.distanceBetweenSource - CGRectGetMaxY(targetRect);
        }
        result = CGSizeMake(MIN(self.maximumWidth, result.width), MIN(self.maximumHeight, result.height));
        return result;
    };
    
    
    CGSize tipSize = [self sizeThatFits:sizeToFitBlock()];
    CGFloat preferredTipWidth = tipSize.width;
    CGFloat preferredTipHeight = tipSize.height;
    CGFloat tipMinX = 0;
    CGFloat tipMinY = 0;
    
    if (self.isVerticalLayoutDirection) {
        // ??????tips?????????????????????self.safetyMarginsAvoidSafeAreaInsets.left
        CGFloat a = CGRectGetMidX(targetRect) - tipSize.width / 2;
        tipMinX = MAX(CGRectGetMinX(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.left, a);
        
        CGFloat tipMaxX = tipMinX + tipSize.width;
        if (tipMaxX + self.safetyMarginsAvoidSafeAreaInsets.right > CGRectGetMaxX(containerRect)) {
            // ???????????????
            // ????????????????????????????????????????????????????????????????????????????????????
            CGFloat distanceCanMoveToLeft = tipMaxX - (CGRectGetMaxX(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.right);
            if (tipMinX - distanceCanMoveToLeft >= CGRectGetMinX(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.left) {
                // ??????????????????
                tipMinX -= distanceCanMoveToLeft;
            } else {
                // ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
                tipMinX = CGRectGetMinX(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.left;
                tipMaxX = CGRectGetMaxX(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.right;
                tipSize.width = MIN(tipSize.width, tipMaxX - tipMinX);
            }
        }
        
        // ?????????????????????????????????tipSize.width????????????????????????????????????????????????????????????????????????????????????sizeThatFits
        BOOL tipWidthChanged = tipSize.width != preferredTipWidth;
        if (tipWidthChanged) {
            tipSize = [self sizeThatFits:tipSize];
        }
        
        // ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
        BOOL canShowAtAbove = [self canTipShowAtSpecifiedLayoutDirect:QMUIPopupContainerViewLayoutDirectionAbove targetRect:targetRect tipSize:tipSize];
        BOOL canShowAtBelow = [self canTipShowAtSpecifiedLayoutDirect:QMUIPopupContainerViewLayoutDirectionBelow targetRect:targetRect tipSize:tipSize];
        
        if (!canShowAtAbove && !canShowAtBelow) {
            // ????????????????????????????????????????????????maximumHeight
            CGFloat maximumHeightAbove = CGRectGetMinY(targetRect) - CGRectGetMinY(containerRect) - self.distanceBetweenSource - self.safetyMarginsAvoidSafeAreaInsets.top;
            CGFloat maximumHeightBelow = CGRectGetMaxY(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.bottom - self.distanceBetweenSource - CGRectGetMaxY(targetRect);
            self.maximumHeight = MAX(self.minimumHeight, MAX(maximumHeightAbove, maximumHeightBelow));
            tipSize.height = self.maximumHeight;
            _currentLayoutDirection = maximumHeightAbove > maximumHeightBelow ? QMUIPopupContainerViewLayoutDirectionAbove : QMUIPopupContainerViewLayoutDirectionBelow;
            
            QMUILog(NSStringFromClass(self.class), @"%@, ???????????????????????????????????????????????????????????????%@, ???????????????%@", self, @(self.maximumHeight), maximumHeightAbove > maximumHeightBelow ? @"??????" : @"??????");
            
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionAbove && !canShowAtAbove) {
            _currentLayoutDirection = QMUIPopupContainerViewLayoutDirectionBelow;
            tipSize.height = [self sizeThatFits:CGSizeMake(tipSize.width, sizeToFitBlock().height)].height;
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow && !canShowAtBelow) {
            _currentLayoutDirection = QMUIPopupContainerViewLayoutDirectionAbove;
            tipSize.height = [self sizeThatFits:CGSizeMake(tipSize.width, sizeToFitBlock().height)].height;
        }
        
        tipMinY = [self tipOriginWithTargetRect:targetRect tipSize:tipSize preferLayoutDirection:_currentLayoutDirection].y;
        
        // ????????????????????????????????????????????????????????????tip?????????safetyMargins??????????????????????????????
        if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionAbove) {
            CGFloat tipMinYIfAlignSafetyMarginTop = CGRectGetMinY(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.top;
            tipMinY = MAX(tipMinY, tipMinYIfAlignSafetyMarginTop);
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow) {
            CGFloat tipMinYIfAlignSafetyMarginBottom = CGRectGetMaxY(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.bottom - tipSize.height;
            tipMinY = MIN(tipMinY, tipMinYIfAlignSafetyMarginBottom);
        }
        
        self.frame = CGRectFlatMake(tipMinX, tipMinY, tipSize.width, tipSize.height);
        
        // ?????????????????????????????????
        CGPoint targetRectCenter = CGPointGetCenterWithRect(targetRect);
        CGFloat selfMidX = targetRectCenter.x - CGRectGetMinX(self.frame);
        _arrowMinX = selfMidX - self.arrowSizeAuto.width / 2;
    } else {
        // ??????tips?????????????????????self.safetyMarginsAvoidSafeAreaInsets.top
        CGFloat a = CGRectGetMidY(targetRect) - tipSize.height / 2;
        tipMinY = MAX(CGRectGetMinY(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.top, a);
        
        CGFloat tipMaxY = tipMinY + tipSize.height;
        if (tipMaxY + self.safetyMarginsAvoidSafeAreaInsets.bottom > CGRectGetMaxY(containerRect)) {
            // ???????????????
            // ????????????????????????????????????????????????????????????????????????????????????
            CGFloat distanceCanMoveToTop = tipMaxY - (CGRectGetMaxY(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.bottom);
            if (tipMinY - distanceCanMoveToTop >= CGRectGetMinY(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.top) {
                // ??????????????????
                tipMinY -= distanceCanMoveToTop;
            } else {
                // ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
                tipMinY = CGRectGetMinY(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.top;
                tipMaxY = CGRectGetMaxY(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.bottom;
                tipSize.height = MIN(tipSize.height, tipMaxY - tipMinY);
            }
        }
        
        // ?????????????????????????????????tipSize.height????????????????????????????????????????????????????????????????????????????????????sizeThatFits
        BOOL tipHeightChanged = tipSize.height != preferredTipHeight;
        if (tipHeightChanged) {
            tipSize = [self sizeThatFits:tipSize];
        }
        
        // ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
        BOOL canShowAtLeft = [self canTipShowAtSpecifiedLayoutDirect:QMUIPopupContainerViewLayoutDirectionLeft targetRect:targetRect tipSize:tipSize];
        BOOL canShowAtRight = [self canTipShowAtSpecifiedLayoutDirect:QMUIPopupContainerViewLayoutDirectionRight targetRect:targetRect tipSize:tipSize];
        
        if (!canShowAtLeft && !canShowAtRight) {
            // ????????????????????????????????????????????????maximumWidth
            CGFloat maximumWidthLeft = CGRectGetMinX(targetRect) - CGRectGetMinX(containerRect) - self.distanceBetweenSource - self.safetyMarginsAvoidSafeAreaInsets.left;
            CGFloat maximumWidthRight = CGRectGetMaxX(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.right - self.distanceBetweenSource - CGRectGetMaxX(targetRect);
            self.maximumWidth = MAX(self.minimumWidth, MAX(maximumWidthLeft, maximumWidthRight));
            tipSize.width = self.maximumWidth;
            _currentLayoutDirection = maximumWidthLeft > maximumWidthRight ? QMUIPopupContainerViewLayoutDirectionLeft : QMUIPopupContainerViewLayoutDirectionRight;
            
            QMUILog(NSStringFromClass(self.class), @"%@, ???????????????????????????????????????????????????????????????%@, ???????????????%@", self, @(self.maximumWidth), maximumWidthLeft > maximumWidthRight ? @"??????" : @"??????");
            
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionLeft && !canShowAtLeft) {
            _currentLayoutDirection = QMUIPopupContainerViewLayoutDirectionLeft;
            tipSize.width = [self sizeThatFits:CGSizeMake(sizeToFitBlock().width, tipSize.height)].width;
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow && !canShowAtRight) {
            _currentLayoutDirection = QMUIPopupContainerViewLayoutDirectionRight;
            tipSize.width = [self sizeThatFits:CGSizeMake(sizeToFitBlock().width, tipSize.height)].width;
        }
        
        tipMinX = [self tipOriginWithTargetRect:targetRect tipSize:tipSize preferLayoutDirection:_currentLayoutDirection].x;
        
        // ????????????????????????????????????????????????????????????tip?????????safetyMargins??????????????????????????????
        if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionLeft) {
            CGFloat tipMinXIfAlignSafetyMarginLeft = CGRectGetMinX(containerRect) + self.safetyMarginsAvoidSafeAreaInsets.left;
            tipMinX = MAX(tipMinX, tipMinXIfAlignSafetyMarginLeft);
        } else if (_currentLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight) {
            CGFloat tipMinXIfAlignSafetyMarginRight = CGRectGetMaxX(containerRect) - self.safetyMarginsAvoidSafeAreaInsets.right - tipSize.width;
            tipMinX = MIN(tipMinX, tipMinXIfAlignSafetyMarginRight);
        }
        
        self.frame = CGRectFlatMake(tipMinX, tipMinY, tipSize.width, tipSize.height);
        
        // ?????????????????????????????????
        CGPoint targetRectCenter = CGPointGetCenterWithRect(targetRect);
        CGFloat selfMidY = targetRectCenter.y - CGRectGetMinY(self.frame);
        _arrowMinY = selfMidY - self.arrowSizeAuto.height / 2;
    }
    
    [self setNeedsLayout];
    
    if (self.debug) {
        self.contentView.backgroundColor = UIColorTestGreen;
        self.borderColor = UIColorRed;
        self.borderWidth = PixelOne;
        _imageView.backgroundColor = UIColorTestRed;
        _textLabel.backgroundColor = UIColorTestBlue;
    }
}

- (CGPoint)tipOriginWithTargetRect:(CGRect)itemRect tipSize:(CGSize)tipSize preferLayoutDirection:(QMUIPopupContainerViewLayoutDirection)direction {
    CGPoint tipOrigin = CGPointZero;
    switch (direction) {
        case QMUIPopupContainerViewLayoutDirectionAbove:
            tipOrigin.y = CGRectGetMinY(itemRect) - tipSize.height - self.distanceBetweenSource;
            break;
        case QMUIPopupContainerViewLayoutDirectionBelow:
            tipOrigin.y = CGRectGetMaxY(itemRect) + self.distanceBetweenSource;
            break;
        case QMUIPopupContainerViewLayoutDirectionLeft:
            tipOrigin.x = CGRectGetMinX(itemRect) - tipSize.width - self.distanceBetweenSource;
            break;
        case QMUIPopupContainerViewLayoutDirectionRight:
            tipOrigin.x = CGRectGetMaxX(itemRect) + self.distanceBetweenSource;
            break;
        default:
            break;
    }
    return tipOrigin;
}

- (BOOL)canTipShowAtSpecifiedLayoutDirect:(QMUIPopupContainerViewLayoutDirection)direction targetRect:(CGRect)itemRect tipSize:(CGSize)tipSize {
    BOOL canShow = NO;
    if (self.isVerticalLayoutDirection) {
        CGFloat tipMinY = [self tipOriginWithTargetRect:itemRect tipSize:tipSize preferLayoutDirection:direction].y;
        if (direction == QMUIPopupContainerViewLayoutDirectionAbove) {
            canShow = tipMinY >= self.safetyMarginsAvoidSafeAreaInsets.top;
        } else if (direction == QMUIPopupContainerViewLayoutDirectionBelow) {
            canShow = tipMinY + tipSize.height + self.safetyMarginsAvoidSafeAreaInsets.bottom <= CGRectGetHeight(self.superview.bounds);
        }
    } else {
        CGFloat tipMinX = [self tipOriginWithTargetRect:itemRect tipSize:tipSize preferLayoutDirection:direction].x;
        if (direction == QMUIPopupContainerViewLayoutDirectionLeft) {
            canShow = tipMinX >= self.safetyMarginsAvoidSafeAreaInsets.left;
        } else if (direction == QMUIPopupContainerViewLayoutDirectionRight) {
            canShow = tipMinX + tipSize.width + self.safetyMarginsAvoidSafeAreaInsets.right <= CGRectGetWidth(self.superview.bounds);
        }
    }
    
    return canShow;
}

- (void)showWithAnimated:(BOOL)animated {
    [self showWithAnimated:animated completion:nil];
}

- (void)showWithAnimated:(BOOL)animated completion:(void (^)(BOOL))completion {
    
    BOOL isShowingByWindowMode = NO;
    if (!self.superview) {
        [self initPopupContainerViewWindowIfNeeded];
        
        QMUICommonViewController *viewController = (QMUICommonViewController *)self.popupWindow.rootViewController;
        viewController.supportedOrientationMask = [QMUIHelper visibleViewController].supportedInterfaceOrientations;
        
        self.previousKeyWindow = UIApplication.sharedApplication.keyWindow;
        [self.popupWindow makeKeyAndVisible];
        
        isShowingByWindowMode = YES;
    } else {
        self.hidden = NO;
    }
    
    [self updateLayout];
    
    if (self.willShowBlock) {
        self.willShowBlock(animated);
    }
    
    if (animated) {
        if (isShowingByWindowMode) {
            self.popupWindow.alpha = 0;
        } else {
            self.alpha = 0;
        }
        self.layer.transform = CATransform3DMakeScale(0.98, 0.98, 1);
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:12 options:UIViewAnimationOptionCurveLinear animations:^{
            self.layer.transform = CATransform3DMakeScale(1, 1, 1);
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if (isShowingByWindowMode) {
                self.popupWindow.alpha = 1;
            } else {
                self.alpha = 1;
            }
        } completion:nil];
    } else {
        if (isShowingByWindowMode) {
            self.popupWindow.alpha = 1;
        } else {
            self.alpha = 1;
        }
        if (completion) {
            completion(YES);
        }
    }
}

- (void)hideWithAnimated:(BOOL)animated {
    [self hideWithAnimated:animated completion:nil];
}

- (void)hideWithAnimated:(BOOL)animated completion:(void (^)(BOOL))completion {
    if (self.willHideBlock) {
        self.willHideBlock(self.hidesByUserTap, animated);
    }
    
    BOOL isShowingByWindowMode = !!self.popupWindow;
    
    if (animated) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if (isShowingByWindowMode) {
                self.popupWindow.alpha = 0;
            } else {
                self.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [self hideCompletionWithWindowMode:isShowingByWindowMode completion:completion];
        }];
    } else {
        [self hideCompletionWithWindowMode:isShowingByWindowMode completion:completion];
    }
}

- (void)hideCompletionWithWindowMode:(BOOL)windowMode completion:(void (^)(BOOL))completion {
    if (windowMode) {
        // ?????? keyWindow ?????????????????????????????????????????? https://github.com/Tencent/QMUI_iOS/issues/90
        if (UIApplication.sharedApplication.keyWindow == self.popupWindow) {
            [self.previousKeyWindow makeKeyWindow];
        }
        
        // iOS 9 ??????iOS 8 ??? 10 ????????????????????????????????????????????? rootViewController ??? popupWindow ????????????????????????????????? layout ??????????????????????????????????????? popupWindow ??????????????? nil??????????????????????????????View ?????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/75
        [self removeFromSuperview];
        self.popupWindow.rootViewController = nil;
        
        self.popupWindow.hidden = YES;
        self.popupWindow = nil;
    } else {
        self.hidden = YES;
    }
    if (completion) {
        completion(YES);
    }
    if (self.didHideBlock) {
        self.didHideBlock(self.hidesByUserTap);
    }
    self.hidesByUserTap = NO;
}

- (BOOL)isShowing {
    BOOL isShowingIfAddedToView = self.superview && !self.hidden && !self.popupWindow;
    BOOL isShowingIfInWindow = self.superview && self.popupWindow && !self.popupWindow.hidden;
    return isShowingIfAddedToView || isShowingIfInWindow;
}

#pragma mark - Private Tools

- (BOOL)isSubviewShowing:(UIView *)subview {
    return subview && !subview.hidden && subview.superview;
}

- (void)initPopupContainerViewWindowIfNeeded {
    if (!self.popupWindow) {
        self.popupWindow = [[QMUIPopupContainerViewWindow alloc] init];
        self.popupWindow.qmui_capturesStatusBarAppearance = NO;
        self.popupWindow.backgroundColor = UIColorClear;
        self.popupWindow.windowLevel = UIWindowLevelQMUIAlertView;
        QMUIPopContainerViewController *viewController = [[QMUIPopContainerViewController alloc] init];
        ((QMUIPopContainerMaskControl *)viewController.view).popupContainerView = self;
        if (self.automaticallyHidesWhenUserTap) {
            viewController.view.backgroundColor = self.maskViewBackgroundColor;
        } else {
            viewController.view.backgroundColor = UIColorClear;
        }
        viewController.supportedOrientationMask = [QMUIHelper visibleViewController].supportedInterfaceOrientations;
        self.popupWindow.rootViewController = viewController;// ?????? rootViewController ??????????????????
        [self.popupWindow.rootViewController.view addSubview:self];
    }
}

/// ??????????????????????????????????????????????????? distanceBetweenSource ????????????????????????????????????????????????????????????????????????????????? contentEdgeInsets ??????
- (CGSize)contentSizeInSize:(CGSize)size {
    CGSize contentSize = CGSizeMake(size.width - UIEdgeInsetsGetHorizontalValue(self.contentEdgeInsets) - self.borderWidth * 2 - self.arrowSpacingInHorizontal, size.height - UIEdgeInsetsGetVerticalValue(self.contentEdgeInsets) - self.borderWidth * 2 - self.arrowSpacingInVertical);
    return contentSize;
}

/// ???????????????????????????????????????????????????????????????self size??????????????????
- (CGSize)sizeWithContentSize:(CGSize)contentSize sizeThatFits:(CGSize)sizeThatFits {
    CGFloat resultWidth = contentSize.width + UIEdgeInsetsGetHorizontalValue(self.contentEdgeInsets) + self.borderWidth * 2 + self.arrowSpacingInHorizontal;
    resultWidth = MAX(MIN(resultWidth, self.maximumWidth), self.minimumWidth);// ??????????????????????????????????????????
    resultWidth = flat(resultWidth);
    
    CGFloat resultHeight = contentSize.height + UIEdgeInsetsGetVerticalValue(self.contentEdgeInsets) + self.borderWidth * 2 + self.arrowSpacingInVertical;
    resultHeight = MAX(MIN(resultHeight, self.maximumHeight), self.minimumHeight);
    resultHeight = flat(resultHeight);
    
    return CGSizeMake(resultWidth, resultHeight);
}

- (BOOL)isHorizontalLayoutDirection {
    return self.preferLayoutDirection == QMUIPopupContainerViewLayoutDirectionLeft || self.preferLayoutDirection == QMUIPopupContainerViewLayoutDirectionRight;
}

- (BOOL)isVerticalLayoutDirection {
    return self.preferLayoutDirection == QMUIPopupContainerViewLayoutDirectionAbove || self.preferLayoutDirection == QMUIPopupContainerViewLayoutDirectionBelow;
}

- (void)setArrowImage:(UIImage *)arrowImage {
    _arrowImage = arrowImage;
    if (arrowImage) {
        _arrowSize = arrowImage.size;
        
        if (!_arrowImageView) {
            _arrowImageView = UIImageView.new;
            _arrowImageView.tintColor = self.backgroundColor;
            [self addSubview:_arrowImageView];
        }
        _arrowImageView.hidden = !!self.backgroundView;// ?????? backgroundView ?????????????????????????????????????????? _arrowImageView ?????????????????? mask ??????
        _arrowImageView.image = arrowImage;
        _arrowImageView.bounds = CGRectMakeWithSize(arrowImage.size);
    } else {
        _arrowImageView.hidden = YES;
        _arrowImageView.image = nil;
    }
}

- (void)setArrowSize:(CGSize)arrowSize {
    if (!self.arrowImage) {
        _arrowSize = arrowSize;
    }
}

// self.arrowSize ?????????????????????????????????????????? tip ????????????????????????arrowSize ??????????????????
- (CGSize)arrowSizeAuto {
    return self.isHorizontalLayoutDirection ? CGSizeMake(self.arrowSize.height, self.arrowSize.width) : self.arrowSize;
}

- (CGFloat)arrowSpacingInHorizontal {
    return self.isHorizontalLayoutDirection ? self.arrowSizeAuto.width : 0;
}

- (CGFloat)arrowSpacingInVertical {
    return self.isVerticalLayoutDirection ? self.arrowSizeAuto.height : 0;
}

- (UIEdgeInsets)safetyMarginsAvoidSafeAreaInsets {
    UIEdgeInsets result = self.safetyMarginsOfSuperview;
    if (self.isHorizontalLayoutDirection) {
        result.left += self.superview.safeAreaInsets.left;
        result.right += self.superview.safeAreaInsets.right;
    } else {
        result.top += self.superview.safeAreaInsets.top;
        result.bottom += self.superview.safeAreaInsets.bottom;
    }
    return result;
}

@end

@implementation QMUIPopupContainerView (UISubclassingHooks)

- (void)didInitialize {
    _backgroundLayer = [CAShapeLayer layer];
    [_backgroundLayer qmui_removeDefaultAnimations];
    [self.layer addSublayer:_backgroundLayer];
    
    _contentView = [[UIView alloc] init];
    self.contentView.clipsToBounds = YES;
    [self addSubview:self.contentView];
    
    // ???????????????????????? showWithAnimated: ????????????????????? window ???????????? appearance ????????? showWithAnimated: ??????????????????????????????????????? showWithAnimated: ???????????????????????? appearance ????????????????????????????????????????????????????????????
    [self qmui_applyAppearance];
}

- (CGSize)sizeThatFitsInContentView:(CGSize)size {
    // ????????????????????????????????????
    if (![self isSubviewShowing:_imageView] && ![self isSubviewShowing:_textLabel]) {
        CGSize selfSize = [self contentSizeInSize:self.bounds.size];
        return selfSize;
    }
    
    CGSize resultSize = CGSizeZero;
    
    BOOL isImageViewShowing = [self isSubviewShowing:_imageView];
    if (isImageViewShowing) {
        CGSize imageViewSize = [_imageView sizeThatFits:size];
        resultSize.width += ceil(imageViewSize.width) + self.imageEdgeInsets.left;
        resultSize.height += ceil(imageViewSize.height) + self.imageEdgeInsets.top;
    }
    
    BOOL isTextLabelShowing = [self isSubviewShowing:_textLabel];
    if (isTextLabelShowing) {
        CGSize textLabelLimitSize = CGSizeMake(size.width - resultSize.width - self.imageEdgeInsets.right, size.height);
        CGSize textLabelSize = [_textLabel sizeThatFits:textLabelLimitSize];
        resultSize.width += (isImageViewShowing ? self.imageEdgeInsets.right : 0) + ceil(textLabelSize.width) + self.textEdgeInsets.left;
        resultSize.height = MAX(resultSize.height, ceil(textLabelSize.height) + self.textEdgeInsets.top);
    }
    return resultSize;
}

@end

@implementation QMUIPopupContainerView (UIAppearance)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    QMUIPopupContainerView *appearance = [QMUIPopupContainerView appearance];
    appearance.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    appearance.arrowSize = CGSizeMake(18, 9);
    appearance.maximumWidth = CGFLOAT_MAX;
    appearance.minimumWidth = 0;
    appearance.maximumHeight = CGFLOAT_MAX;
    appearance.minimumHeight = 0;
    appearance.preferLayoutDirection = QMUIPopupContainerViewLayoutDirectionAbove;
    appearance.distanceBetweenSource = 5;
    appearance.safetyMarginsOfSuperview = UIEdgeInsetsMake(10, 10, 10, 10);
    appearance.backgroundColor = UIColorWhite;// ?????????????????? UIView.appearance.backgroundColor???????????????????????? method_exchangeImplementations ?????? UIView.setBackgroundColor ??????????????? crash???QMUI ???????????? +initialize ?????????????????????????????? hook -[UIView setBackgroundColor:] ???????????? +initialize ????????????
    appearance.maskViewBackgroundColor = UIColorMask;
    appearance.highlightedBackgroundColor = nil;
    appearance.shadow = [NSShadow qmui_shadowWithColor:UIColorMakeWithRGBA(0, 0, 0, .1) shadowOffset:CGSizeMake(0, 2) shadowRadius:10];
    appearance.borderColor = UIColorGrayLighten;
    appearance.borderWidth = PixelOne;
    appearance.cornerRadius = 10;
    appearance.qmui_outsideEdge = UIEdgeInsetsZero;
    
}

@end

@implementation QMUIPopContainerViewController

- (void)loadView {
    QMUIPopContainerMaskControl *maskControl = [[QMUIPopContainerMaskControl alloc] init];
    self.view = maskControl;
}

@end

@implementation QMUIPopContainerMaskControl

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(handleMaskEvent:) forControlEvents:UIControlEventTouchDown];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if (result == self) {
        if (!self.popupContainerView.automaticallyHidesWhenUserTap) {
            return nil;
        }
    }
    return result;
}

// ?????????????????????????????? addTarget: ?????????????????? hitTest:withEvent: ?????????????????? hitTest:withEvent: ??????????????????
- (void)handleMaskEvent:(id)sender {
    if (self.popupContainerView.automaticallyHidesWhenUserTap) {
        self.popupContainerView.hidesByUserTap = YES;
        [self.popupContainerView hideWithAnimated:YES];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.popupContainerView updateLayout];// ??????????????????????????? sourceView window ?????????????????? popupWindow ???????????????????????? popupWindow ???????????????????????????????????? popup ?????????
}

@end

@implementation QMUIPopupContainerViewWindow

// ?????? UIWindow ??????????????????????????????????????????????????????
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if (result == self) {
        return nil;
    }
    return result;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.rootViewController.view.frame = self.bounds;// ???????????????????????????????????????
}

@end
