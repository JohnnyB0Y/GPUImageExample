//
//  BeautyViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/11.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "BeautyViewController.h"
#import <GPUImage/GPUImage.h>
#import <Masonry/Masonry.h>
#import <Photos/Photos.h>
#import <AGTimerManager/AGTimerManager.h>

#import "../Filters/GPUImageBeautyFilter.h"
#import "../Filters/CLRGPUImageFiler.h"
#import "../Filters/GPUImageJoggleFilter.h"
#import "../Filters/GPUImageInvertedMirrorFilter.h"
#import "AGPopupManager.h"


@interface BeautyViewController ()

/** beauty button */
@property (nonatomic, strong) UIButton *beautyBtn;
/** record button */
@property (nonatomic, strong) UIButton *recordBtn;
/** time label */
@property (nonatomic, strong) UILabel *timeLabel;
/** change button */
@property (nonatomic, strong) UIButton *changeBtn;

/** video camera */
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;

///** 人脸识别 */
//@property (nonatomic, strong) AVCaptureMetadataOutput *captureMetadataOutput;

/** filter view */
@property (nonatomic, strong) GPUImageView *filterView;

/** beauty filter */
@property (nonatomic, strong) GPUImageBeautyFilter *beautyFilter;
/** CLR filter */
@property (nonatomic, strong) CLRGPUImageFiler *clrFilter;

@end

@implementation BeautyViewController {
    NSArray *_filters; // 一些滤镜
    GPUImageMovieWriter *_movieWriter; // 保存视频类
    NSString *_movieURLString; // 存储视频的URL
    GPUImageOutput<GPUImageInput> *_currentFilter; // 当前的滤镜
    
    AGTimerManager *_timerManager; // 计时使用
}

#pragma mark - ----------- Life Cycle ----------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ...
    self.title = @"美颜相机";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *itemImage = [UIImage imageNamed:@"exchange_camera"];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:itemImage style:UIBarButtonItemStyleDone target:self action:@selector(exchangeCamera:)];
    self.navigationItem.rightBarButtonItem = item;
    
    // ...
    [self.view addSubview:self.filterView];
    [self.view addSubview:self.beautyBtn];
    [self.view addSubview:self.recordBtn];
    [self.view addSubview:self.changeBtn];
    [self.view addSubview:self.timeLabel];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // ...
        [self.videoCamera addTarget:self.filterView];
        [self.videoCamera addAudioInputsAndOutputs];
        [self.videoCamera startCameraCapture];
        
        _filters = @[[GPUImageStretchDistortionFilter new],
                     [GPUImageLocalBinaryPatternFilter new],
                     [GPUImageSketchFilter new],
                     [GPUImageColorInvertFilter new]];
        
        /**
         
         [GPUImageStretchDistortionFilter new],
         [GPUImageLocalBinaryPatternFilter new],
         [GPUImageSketchFilter new],
         [GPUImageColorInvertFilter new]
         
         */
        
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
    
    [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.bottom.mas_equalTo(self.view.mas_bottom).mas_offset(-44.);
    }];
    
    [self.beautyBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.recordBtn.mas_left).mas_offset(-16.);
        make.centerY.mas_equalTo(self.recordBtn);
    }];
    
    [self.changeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.recordBtn.mas_right).mas_offset(16.);
        make.centerY.mas_equalTo(self.recordBtn);
    }];
    
    [self.timeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.top.mas_equalTo(self.view.mas_top).mas_offset(68.);
    }];
}

#pragma mark - ---------- Private Methods ----------
- (void) _startRecord
{
    // 禁用其他按钮
    self.beautyBtn.hidden = YES;
    self.changeBtn.hidden = YES;
    
    NSString *movieName = [NSString stringWithFormat:@"My_%@_Movie", @([NSDate new].timeIntervalSince1970)];
    _movieURLString = [NSString stringWithFormat:@"%@/Documents/%@.m4v", NSHomeDirectory(), movieName];
    NSURL *movieURL = [NSURL fileURLWithPath:_movieURLString];
    
    unlink([_movieURLString UTF8String]); // 如果已经存在文件，AVAssetWriter会有异常，删除旧文件
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    _movieWriter.encodingLiveVideo = YES;
    
    // ...
    if ( _currentFilter ) {
        // 有滤镜
        [_currentFilter addTarget:_movieWriter];
    }
    else {
        // 无滤镜
        [_videoCamera addTarget:_movieWriter];
    }
    
    _videoCamera.audioEncodingTarget = _movieWriter;
    [_movieWriter startRecording];
    
    // 开始计时
    [self _startTimer];
}

- (void) _stopRecord
{
    self.beautyBtn.hidden = NO;
    self.changeBtn.hidden = NO;
    
    [_currentFilter removeTarget:_movieWriter];
    _videoCamera.audioEncodingTarget = nil;
    [_movieWriter finishRecording];
    
    // 停止计时
    [self _stopTimer];
    
    // 创建视频文件
    if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(_movieURLString) ) {
        // 0.判断状态
        switch ( [PHPhotoLibrary authorizationStatus] ) {
            case PHAuthorizationStatusDenied: {
                NSLog(@"用户拒绝当前应用访问相册。");
            } break;
                
            case PHAuthorizationStatusRestricted: {
                NSLog(@"家长控制, 不允许访问相册。");
            } break;
                
            case PHAuthorizationStatusNotDetermined: {
                NSLog(@"用户还未授权访问相册。");
                [self _creationVideo];
            } break;
                
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"已授权应用访问相册。");
                [self _creationVideo];
            } break;
        }
    }
}

- (void) _creationVideo
{
    NSURL *movieURL = [NSURL URLWithString:_movieURLString];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // 创建视频
        [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (error) {
                UIAlertController *alertVC = [[AGPopupManager sharedInstance] ag_alertController:nil title:@"保存视频失败" message:nil preferredStyle:UIAlertControllerStyleAlert cancelTitle:@"OK" alertActionTitles:nil operationBlocks:nil];
                [self presentViewController:alertVC animated:YES completion:nil];
                
            } else {
                UIAlertController *alertVC = [[AGPopupManager sharedInstance] ag_alertController:nil title:@"保存视频成功" message:nil preferredStyle:UIAlertControllerStyleAlert cancelTitle:@"OK" alertActionTitles:nil operationBlocks:nil];
                [self presentViewController:alertVC animated:YES completion:nil];
                
            }
        });
    }];
}

- (void) _startTimer
{
    if ( _timerManager == nil ) {
        _timerManager = [[AGTimerManager alloc] init];
    }
    // 计时
    static NSInteger count;
    count = 0;
    
    __weak typeof(self) weakSelf = self;
    [_timerManager ag_startRepeatTimer:1. delay:1. repeat:^BOOL{
        __strong typeof(weakSelf) self = weakSelf;
        [self.timeLabel setText:[NSString stringWithFormat:@"%@ 秒", @(++count)]];
        
        // ...
        return self != nil;
    }];
}

- (void) _stopTimer
{
    self.timeLabel.text = @"OFF";
    [_timerManager ag_stopAllTimers];
}

#pragma mark - ---------- Event Methods ----------
- (void) beautyBtnClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
    // 移除滤镜
    [self.videoCamera removeAllTargets];
    
    if ( btn.selected ) {
        // 开启美颜滤镜
        _currentFilter = self.beautyFilter;
        [self.beautyFilter addTarget:self.filterView];
        [self.videoCamera addTarget:self.beautyFilter];
        
    }
    else {
        [self.videoCamera addTarget:self.filterView];
    }
    
}

- (void)recordBtnClick:(UIButton *)btn {
    
    btn.selected = !btn.selected;
    
    if ( btn.selected ) {
        NSLog(@"Start recording!");
        
        [self _startRecord];
    }
    else {
        NSLog(@"End recording!");
        
        [self _stopRecord];
    }
}

- (void) changeBtnClick:(UIButton *)btn
{
    static int idx = -1;
    if ( ++idx == _filters.count ) {
        idx = 0;
    }
    // 切换系统滤镜
    _currentFilter = _filters[idx];
    [_currentFilter addTarget:self.filterView];
    
    [self.videoCamera removeAllTargets];
    [self.videoCamera addTarget:_currentFilter];
    
}

- (void) exchangeCamera:(UIBarButtonItem *)item
{
    [self.videoCamera rotateCamera];
}

- (void)refreshDisp:(CADisplayLink *)displayLink {
    static float timeLast = 0;
    float time = sin( CACurrentMediaTime() );
    time = (((time + 1.0)/2.0) * 1.5 ) - 0.5;
    if((time - timeLast) > 0.0) {
        _clrFilter.upDown = 0.6;
    }
    else {
        _clrFilter.upDown = 0.0;
    }
    timeLast = time;
    _clrFilter.inputData = time;
}

#pragma mark - ----------- Getter Methods ----------
- (UIButton *)beautyBtn
{
    if (_beautyBtn == nil) {
        _beautyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_beautyBtn setTitle:@"打开美颜" forState:UIControlStateNormal];
        [_beautyBtn setTitle:@"关闭美颜" forState:UIControlStateSelected];
        _beautyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        [_beautyBtn addTarget:self action:@selector(beautyBtnClick:) forControlEvents:UIControlEventTouchDown];
    }
    return _beautyBtn;
}

- (UIButton *)recordBtn
{
    if (_recordBtn == nil) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_recordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
        [_recordBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_recordBtn setTitle:@"结束录制" forState:UIControlStateSelected];
        [_recordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _recordBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        [_recordBtn addTarget:self action:@selector(recordBtnClick:) forControlEvents:UIControlEventTouchDown];
    }
    return _recordBtn;
}

- (UIButton *)changeBtn
{
    if (_changeBtn == nil) {
        _changeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_changeBtn setTitle:@"切换滤镜" forState:UIControlStateNormal];
        [_changeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _changeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_changeBtn addTarget:self action:@selector(changeBtnClick:) forControlEvents:UIControlEventTouchDown];
    }
    return _changeBtn;
}

- (UILabel *)timeLabel
{
    if (_timeLabel == nil) {
        _timeLabel = [UILabel new];
        _timeLabel.text = @"OFF";
        _timeLabel.textColor = [UIColor redColor];
        _timeLabel.backgroundColor = [UIColor clearColor];
    }
    return _timeLabel;
}

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
        _filterView.backgroundColor = [UIColor blackColor];
    }
    return _filterView;
}

- (GPUImageBeautyFilter *)beautyFilter
{
    if (_beautyFilter == nil) {
        _beautyFilter = [[GPUImageBeautyFilter alloc] init];
    }
    return _beautyFilter;
}

- (CLRGPUImageFiler *)clrFilter
{
    if (_clrFilter == nil) {
        _clrFilter = [CLRGPUImageFiler new];
    }
    return _clrFilter;
}

@end
