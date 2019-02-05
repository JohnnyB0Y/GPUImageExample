//
//  AGProgressHUD.h
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AGProgressHUDSetupBlock)(UIView *container);

@interface AGProgressHUD : UIView

/** bg */
@property (nonatomic, strong, readonly) UIView *backgroundView;
/** track */
@property (nonatomic, strong, readonly) UIView *trackView;

/** leading view */
@property (nonatomic, strong, readonly) UIView *leadingView;
/** current view */
@property (nonatomic, strong, readonly) UIView *currentView;
/** trailing view */
@property (nonatomic, strong, readonly) UIView *trailingView;


@property(nonatomic, strong, nullable) UIColor *backgroundTintColor; // default is lightGrayColor
@property(nonatomic, strong, nullable) UIColor *trackTintColor; // default is blueColor

@property(nonatomic, assign) CGFloat progressLeading; // 头间距, default is 0.0.
@property(nonatomic, assign) CGFloat progress; // 0.0 .. 1.0, default is 0.0.
@property(nonatomic, assign) CGFloat progressTrailing; // 尾间距, default is 0.0.

- (void) ag_setProgress:(CGFloat)progress animated:(BOOL)animated;


- (void) ag_setupProgressBackgroundViewUsingBlock:(AGProgressHUDSetupBlock)block; // 背景View
- (void) ag_setupProgressTrackViewUsingBlock:(AGProgressHUDSetupBlock)block; // 进度条View
- (void) ag_setupProgressLeadingViewUsingBlock:(AGProgressHUDSetupBlock)block; // 起点上的View
- (void) ag_setupProgressCurrentViewUsingBlock:(AGProgressHUDSetupBlock)block; // 进度点上的View
- (void) ag_setupProgressTrailingViewUsingBlock:(AGProgressHUDSetupBlock)block; // 终点上的View

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
