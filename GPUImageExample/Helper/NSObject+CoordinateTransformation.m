//
//  NSObject+CoordinateTransformation.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/16.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//  坐标转换

#import "NSObject+CoordinateTransformation.h"

@implementation NSObject (CoordinateTransformation)
#pragma mark UIKit 与 OpenGL 坐标系转换
+ (UIPoint) ag_UIPointFromGL:(GLPoint)point forScreen:(CGSize)size
{
    point.x = (size.width * (point.x * 0.5 + 0.5));
    point.y = (size.height * (0.5 - point.y * 0.5));
    return point;
}

+ (UIRect ) ag_UIRectFromGL :(GLRect )rect  forScreen:(CGSize)size
{
    CGPoint point = [self ag_UIPointFromGL:rect.origin forScreen:size];
    rect.origin.x = point.x;
    rect.origin.y = point.y;
    return rect;
}

+ (GLPoint) ag_GLPointFromUI:(UIPoint)point forScreen:(CGSize)size
{
    point.x = (2. * point.x / size.width - 1.);
    point.y = (1. - 2. * point.y / size.height);
    return point;
}

+ (GLRect ) ag_GLRectFromUI :(UIRect )rect  forScreen:(CGSize)size
{
    CGPoint point = [self ag_GLPointFromUI:rect.origin forScreen:size];
    rect.origin.x = point.x;
    rect.origin.y = point.y;
    return rect;
}

#pragma mark UIKit 与 CoreGraphics 坐标系转换
+ (UIPoint) ag_UIPointFromCG:(CGPoint)point forScreen:(CGSize)size
{
    point.y = size.height - point.y;
    return point;
}

+ (UIRect ) ag_UIRectFromCG:(CGRect )rect forScreen:(CGSize)size
{
    rect.origin.y = [self ag_UIPointFromCG:rect.origin forScreen:size].y;
    return rect;
}

+ (CGPoint) ag_CGPointFromUI:(UIPoint)point forScreen:(CGSize)size
{
    point.y = size.height - point.y;
    return point;
}

+ (CGRect ) ag_CGRectFromUI:(UIRect )rect forScreen:(CGSize)size
{
    rect.origin.y = [self ag_CGPointFromUI:rect.origin forScreen:size].y;
    return rect;
}

#pragma mark 坐标旋转 （x，y交换；w，h交换）
+ (CGRect ) ag_CGRectClockwise90:(CGRect)rect
{
    CGPoint temP = rect.origin;
    CGSize temS = rect.size;
    
    rect.origin.x = temP.y;
    rect.origin.y = temP.x;
    rect.size.width = temS.height;
    rect.size.height = temS.width;
    return rect;
}

+ (CGRect ) ag_CGRectAnticlockwise90:(CGRect)rect
{
    return [self ag_CGRectClockwise90:rect];
}

@end
