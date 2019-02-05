//
//  AnimationViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

#import "AnimationViewController.h"
#import "../Views/AGBreezeHUD.h"
#import "../Views/AGProgressHUD.h"
#import <AGTimerManager/AGTimerManager.h>

@interface AnimationViewController ()

/** timer */
@property (nonatomic, strong) AGTimerManager *timerManager;

/** progressHUD */
@property (nonatomic, strong) AGProgressHUD *progressHUD;
/** breezeHUD */
@property (nonatomic, strong) AGBreezeHUD *breezeHUD;
@end

@implementation AnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _addProgressHUD];
    [self _addBreezeHUD];
    
    // 模拟下载
    __weak typeof(self) weakSelf = self;
    _timerManager = [[AGTimerManager alloc] init];
    [_timerManager ag_startCountdownTimer:10 countdown:^BOOL(NSTimeInterval surplus) {
        
        __strong typeof(weakSelf) self = weakSelf;
        if ( self ) {
            [self.breezeHUD ag_setProgress:(10 - surplus) / 10. animated:YES];
        }
        
        return YES;
    } completion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if ( self ) {
            [self.breezeHUD setProgress:1.0];
            
            
        }
        
    }];
    
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *t = [touches anyObject];
    
    CGPoint p = [t locationInView:self.view];
    
    CGFloat progress = p.x / self.view.frame.size.width;
    
    _progressHUD.progress = progress;
    //_breezeHUD.progress = progress;
}

#pragma mark - ---------- Private Methods ----------
- (void) _addBreezeHUD
{
    _breezeHUD = [[AGBreezeHUD alloc] initWithFrame:CGRectMake(44, 200, 320, 64)];
    
    
    
    [self.view addSubview:_breezeHUD];
}

- (void) _addProgressHUD
{
    _progressHUD = [[AGProgressHUD alloc] initWithFrame:CGRectMake(44, 144, 320, 44)];
    
    _progressHUD.progressLeading = 44.;
    _progressHUD.progressTrailing = 44.;
    
    [_progressHUD ag_setupProgressBackgroundViewUsingBlock:^(UIView * _Nonnull container) {
        container.layer.cornerRadius = 22.;
        container.layer.masksToBounds = YES;
        
    }];
    
    [_progressHUD ag_setupProgressLeadingViewUsingBlock:^(UIView * _Nonnull container) {
        container.backgroundColor = [UIColor yellowColor];
        container.layer.cornerRadius = 22.;
        container.layer.masksToBounds = YES;
        container.layer.borderColor = [UIColor orangeColor].CGColor;
        container.layer.borderWidth = 4.0;
    }];
    
    [_progressHUD ag_setupProgressCurrentViewUsingBlock:^(UIView * _Nonnull container) {
        container.backgroundColor = [UIColor whiteColor];
        container.layer.cornerRadius = 22.;
        container.layer.masksToBounds = YES;
        container.layer.borderColor = [UIColor blueColor].CGColor;
        container.layer.borderWidth = 4.0;
        
    }];
    
    [_progressHUD ag_setupProgressTrailingViewUsingBlock:^(UIView * _Nonnull container) {
        container.bounds = CGRectMake(0, 0, 60, 60);
        container.backgroundColor = [UIColor yellowColor];
        container.layer.cornerRadius = 6.;
        container.layer.masksToBounds = YES;
        container.layer.borderColor = [UIColor greenColor].CGColor;
        container.layer.borderWidth = 4.0;
    }];
    
    [self.view addSubview:_progressHUD];
}

@end
