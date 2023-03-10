/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UIBezierPath+QMUI.h
//  qmui
//
//  Created by QMUI Team on 16/8/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (QMUI)

/**
 * 创建一条支持四个角的圆角值不相同的路径
 * @param rect 路径的rect
 * @param cornerRadius 圆角大小的数字，长度必须为4，顺序分别为[左上角、左下角、右下角、右上角]
 * @param lineWidth 描边的大小，如果不需要描边（例如path是用于fill而不是用于stroke），则填0
 */
+ (instancetype)qmui_bezierPathWithRoundedRect:(CGRect)rect cornerRadiusArray:(NSArray<NSNumber *> *)cornerRadius lineWidth:(CGFloat)lineWidth;

/**
 创建一条尺寸为[0,1]的正方形区域内的曲线，曲线由 CAMediaTimingFunction 转换而来。如果希望得到不同尺寸的 path，请通过 -[UIBezierPath applyTransform:] 转换。
 */
+ (instancetype)qmui_bezierPathWithMediaTimingFunction:(CAMediaTimingFunction *)function;
@end

NS_ASSUME_NONNULL_END
