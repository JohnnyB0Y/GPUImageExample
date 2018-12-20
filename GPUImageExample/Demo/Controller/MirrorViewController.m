//
//  MirrorViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/20.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "MirrorViewController.h"
#import "GPUImageInvertedMirrorFilter.h"
#import <GPUImage/GPUImage.h>
#import <Masonry.h>

@interface MirrorViewController ()

@property (nonatomic, strong) GPUImageInvertedMirrorFilter *mirrorFilter;
/** video camera */
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
/** filter view */
@property (nonatomic, strong) GPUImageView *filterView;

@end

@implementation MirrorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"倒影镜像";
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [self.view addSubview:self.filterView];
    
    // 初始化镜像倒影滤镜
    self.mirrorFilter = [[GPUImageInvertedMirrorFilter alloc] initWithVideoCamera:self.videoCamera];
    [self.mirrorFilter addTarget:self.filterView]; // 添加到响应链
    
    // 开启摄像头
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // ...
        [self.videoCamera addAudioInputsAndOutputs];
        [self.videoCamera startCameraCapture];

    });
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // 移除所有滤镜、输入输出
    [self.videoCamera removeAllTargets];
    [self.videoCamera removeInputsAndOutputs];
    // 释放内存
    [[[GPUImageContext sharedImageProcessingContext] framebufferCache] purgeAllUnassignedFramebuffers];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.filterView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
}

#pragma mark - ----------- Getter Methods ----------
- (GPUImageVideoCamera *)videoCamera
{
    if (_videoCamera == nil) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                                           cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    }
    return _videoCamera;
}

- (GPUImageView *)filterView
{
    if (_filterView == nil) {
        _filterView = [[GPUImageView alloc] init];
        _filterView.fillMode = kGPUImageFillModeStretch;
        _filterView.backgroundColor = [UIColor blackColor];
    }
    return _filterView;
}

@end
