//
//  AGBreezeHUD.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

#import "AGBreezeHUD.h"

@interface AGBreezeHUD ()
<CAAnimationDelegate>


@end

/**
 1, 右边有个风扇旋转
 - 风扇是独立的动画视图 -- ok
 - 控制风扇向左转或者向右转 -- ok
 - 控制风扇的速度
 
 2, 风扇吹出气泡
 - 根据具体数值，生成不同大小的气泡
 - 气泡会沿着轨迹走动
 - 气泡吹到左边进度条边界后，消失，并增加进度条的长度。
 - 气泡碰到进度条边界，消失的时候有动画效果。
 */

@implementation AGBreezeHUD

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( nil == self ) return nil;
    
    _rotationToLeft = NO;
    
    [self ag_setupProgressTrailingViewUsingBlock:^(UIView * _Nonnull container) {
        
        container.layer.cornerRadius = frame.size.height * 0.5;
        container.layer.masksToBounds = YES;
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = container.bounds;
        [container.layer addSublayer:gradientLayer];
        
        gradientLayer.colors = @[(__bridge id)[UIColor redColor].CGColor,
                                 (__bridge id)[UIColor greenColor].CGColor,
                                 (__bridge id)[UIColor blueColor].CGColor];
        
        gradientLayer.locations = @[@0.0, @0.5, @1.0];
        
        //set gradient start and end points
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 1);
        
        // 旋转
        [self _rotationLayer:container.layer toLeft:_rotationToLeft duration:2.5 repeatCount:NSIntegerMax forKey:nil];
    }];
    
    return self;
}

#pragma mark - ---------- Public Methods ----------
- (void)setProgress:(CGFloat)progress
{
    [super setProgress:progress];
    // stop animation
    if ( progress >= 1.0 ) {
        [self _stopRotationLayer];
    }
}

/* Called when the animation begins its active duration. */

- (void)animationDidStart:(CAAnimation *)anim
{
    
}

/* Called when the animation either completes its active duration or
 * is removed from the object it is attached to (i.e. the layer). 'flag'
 * is true if the animation reached the end of its active duration
 * without being removed. */

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    
}

#pragma mark - ---------- Private Methods ----------
- (void) _rotationLayer:(CALayer *)layer
                 toLeft:(BOOL)yesOrNo
               duration:(CFTimeInterval)duration
            repeatCount:(float)repeatCount
                 forKey:(NSString *)key
{
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"transform.rotation";
    animation.duration = duration;
    animation.byValue = yesOrNo ? @(-M_PI * 2) : @(M_PI * 2);
    animation.repeatCount = repeatCount;
    [layer addAnimation:animation forKey:key];
}

- (void) _stopRotationLayer
{
    [self.trailingView.layer removeAllAnimations];
}

@end
