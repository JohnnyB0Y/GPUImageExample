//
//  NSObject+CoordinateTransformation.h
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/16.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//  坐标转换

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef CGPoint UIPoint;
typedef CGPoint GLPoint;
typedef CGRect UIRect;
typedef CGRect GLRect;

@interface NSObject (CoordinateTransformation)

#pragma mark UIKit 与 OpenGL 坐标系转换
+ (UIPoint) ag_UIPointFromGL:(GLPoint)point forScreen:(CGSize)size;
+ (UIRect ) ag_UIRectFromGL :(GLRect )rect  forScreen:(CGSize)size;

+ (GLPoint) ag_GLPointFromUI:(UIPoint)point forScreen:(CGSize)size;
+ (GLRect ) ag_GLRectFromUI :(UIRect )rect  forScreen:(CGSize)size;

#pragma mark UIKit 与 CoreGraphics 坐标系转换
+ (UIPoint) ag_UIPointFromCG:(CGPoint)point forScreen:(CGSize)size;
+ (UIRect ) ag_UIRectFromCG :(CGRect )rect  forScreen:(CGSize)size;

+ (CGPoint) ag_CGPointFromUI:(UIPoint)point forScreen:(CGSize)size;
+ (CGRect ) ag_CGRectFromUI :(UIRect )rect  forScreen:(CGSize)size;

#pragma mark 坐标旋转90度（x，y交换；w，h交换）
+ (CGRect ) ag_CGRectClockwise90:(CGRect)rect;
+ (CGRect ) ag_CGRectAnticlockwise90:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
