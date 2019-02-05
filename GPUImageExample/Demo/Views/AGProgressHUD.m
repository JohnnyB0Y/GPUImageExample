//
//  AGProgressHUD.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

#import "AGProgressHUD.h"

@interface AGProgressHUD ()

/** bg */
@property (nonatomic, strong) UIView *backgroundView;
/** track */
@property (nonatomic, strong) UIView *trackView;

/** leading view */
@property (nonatomic, strong) UIView *leadingView;
/** current view */
@property (nonatomic, strong) UIView *currentView;
/** trailing view */
@property (nonatomic, strong) UIView *trailingView;

/** progress width */
@property (nonatomic, assign) float progressWidth;

@end

/**
 
 1, 可以裁边的进度条
 - 三个位置点，起点，当前点（变化），终点。-- ok
 - 视图图层：父视图-，背景视图-，进度条视图-，起点视图，终点视图，当前点视图（变化）。-- ok
 
 - 裁圆角 -- ok
 - 根据数值，设置进度 -- ok
 -- 设置进度条计数的起点和终点 -- ok
 -- 根据具体数值和进度条长度，计算进度比例 -- ok
 
 */

@implementation AGProgressHUD

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( nil == self ) return nil;
    
    [self _initSubView];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( nil == self ) return nil;
    
    [self _initSubView];
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self _initSubView];
}

#pragma mark - ---------- Public Methods ----------
- (void)ag_setProgress:(CGFloat)progress animated:(BOOL)animated
{
    if ( animated ) {
        [UIView animateWithDuration:0.25 animations:^{
            [self setProgress:progress];
        }];
    }
    else {
        [self setProgress:progress];
    }
}

- (void)ag_setupProgressBackgroundViewUsingBlock:(AGProgressHUDSetupBlock)block
{
    if ( block ) {
        block(_backgroundView);
    }
}

- (void)ag_setupProgressTrackViewUsingBlock:(AGProgressHUDSetupBlock)block
{
    if ( block ) {
        [self _adjustHUDProgress];
        _trackView.frame = CGRectMake(_progressLeading, _progressTrailing, _progressWidth, self.bounds.size.height);
        block(_trackView);
    }
}

- (void)ag_setupProgressLeadingViewUsingBlock:(AGProgressHUDSetupBlock)block
{
    if ( block ) {
        block(self.leadingView);
    }
}

- (void)ag_setupProgressCurrentViewUsingBlock:(AGProgressHUDSetupBlock)block
{
    if ( block ) {
        [self _adjustHUDProgress];
        block(self.currentView);
    }
}

- (void)ag_setupProgressTrailingViewUsingBlock:(AGProgressHUDSetupBlock)block
{
    if ( block ) {
        block(self.trailingView);
    }
}

#pragma mark - ----------- Override Methods ----------
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self _adjustHUDProgress];
    
}

#pragma mark - ---------- Private Methods ----------
- (void) _adjustHUDProgress
{
    //
    CGFloat bgX = 0.;
    CGFloat bgY = 0.;
    CGFloat bgW = self.bounds.size.width;
    CGFloat bgH = self.bounds.size.height;
    _backgroundView.frame = CGRectMake(bgX, bgY, bgW, bgH);
    
    //
    _progressWidth = bgW - _progressLeading - _progressTrailing;
    
    //
    CGFloat x = _progressLeading;
    CGFloat y = bgY;
    CGFloat w = [self trackViewWidth];
    CGFloat h = bgH;
    _trackView.frame = CGRectMake(x, y, w, h);
}

- (void) _updateHUDProgress
{
    CGFloat x = _trackView.frame.origin.x;
    CGFloat y = _trackView.frame.origin.y;
    CGFloat w = [self trackViewWidth];
    CGFloat h = _trackView.frame.size.height;
    _trackView.frame = CGRectMake(x, y, w, h);
    
    if ( _currentView ) {
        CGFloat centerY = _currentView.center.y;
        _currentView.center = CGPointMake([self trackViewX], centerY);
    }
}

- (void) _initSubView
{
    self.backgroundColor = [UIColor clearColor];
    
    _progressWidth = 0.0;
    _progressLeading = 0.0;
    _progressTrailing = 0.0;
    _progress = 0.0; // default
    
    _backgroundView = [UIView new];
    _trackView = [UIView new];
    
    [self addSubview:_backgroundView];
    [_backgroundView addSubview:_trackView];
    
    _backgroundView.frame = self.bounds;
    _trackView.frame = CGRectMake(0, 0, 1.0, self.bounds.size.height);
    
    _backgroundView.backgroundColor = [UIColor lightGrayColor];
    _trackView.backgroundColor = [UIColor blueColor];
    
    [self _adjustHUDProgress];
}

#pragma mark - ----------- Setter Methods ----------
- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    _trackTintColor = trackTintColor;
    [_trackView setBackgroundColor:trackTintColor];
}

- (void)setBackgroundTintColor:(UIColor *)backgroundTintColor
{
    _backgroundTintColor = backgroundTintColor;
    [_backgroundView setBackgroundColor:backgroundTintColor];
}

- (void)setProgressLeading:(CGFloat)progressLeading
{
    _progressLeading = progressLeading;
    [self _adjustHUDProgress];
    [self _updateHUDProgress];
}

- (void)setProgressTrailing:(CGFloat)progressTrailing
{
    _progressTrailing = progressTrailing;
    [self _adjustHUDProgress];
    [self _updateHUDProgress];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self _updateHUDProgress];
}

#pragma mark - ----------- Getter Methods ----------
- (CGFloat) trackViewWidth
{
    return _progressWidth * _progress;
}

- (CGFloat) trackViewX
{
    return [self trackViewWidth] + _progressLeading;
}

- (UIView *)leadingView
{
    if (_leadingView == nil) {
        _leadingView = [UIView new];
        [self insertSubview:_leadingView atIndex:2];
        CGFloat height = self.bounds.size.height;
        _leadingView.bounds = CGRectMake(0, 0, height, height);
        _leadingView.center = CGPointMake(_progressLeading, height * 0.5);
    }
    return _leadingView;
}

- (UIView *)trailingView
{
    if (_trailingView == nil) {
        _trailingView = [UIView new];
        [self insertSubview:_trailingView atIndex:2];
        CGFloat height = self.bounds.size.height;
        CGFloat width = self.bounds.size.width;
        _trailingView.bounds = CGRectMake(0, 0, height, height);
        _trailingView.center = CGPointMake(width - _progressTrailing, height * 0.5);
    }
    return _trailingView;
}

- (UIView *)currentView
{
    if (_currentView == nil) {
        _currentView = [UIView new];
        [self addSubview:_currentView];
        CGFloat height = self.bounds.size.height;
        _currentView.bounds = CGRectMake(0, 0, height, height);
        _currentView.center = CGPointMake([self trackViewX], height * 0.5);
    }
    return _currentView;
}

@end
