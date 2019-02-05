//
//  FaceViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/14.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "FaceViewController.h"
#import <GPUImage/GPUImage.h>
#import <Masonry/Masonry.h>

@interface FaceViewController ()
<GPUImageVideoCameraDelegate>

/** 人脸检测器 */
@property (nonatomic, strong) CIDetector *faceDetector;

/** video camera */
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;

/** 圣诞帽 */
@property (nonatomic, strong) UIImageView *hatImageView;

/** 框脸用的 */
@property (nonatomic, strong) UIImageView *faceWindow;

@end

@implementation FaceViewController {
    CGSize _hatOriginS; // 帽子原始大小
    CGSize _filterViewS; // 内容视图的大小
    NSUInteger _sampleCount; // 记录采样数，用于限制人脸识别次数
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // ...
    _sampleCount = 0;
    self.title = @"人脸识别";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *itemImage = [UIImage imageNamed:@"exchange_camera"];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:itemImage style:UIBarButtonItemStyleDone target:self action:@selector(exchangeCamera:)];
    self.navigationItem.rightBarButtonItem = item;
    
    // ...
    [self.view addSubview:self.filterView];
    [self.filterView addSubview:self.hatImageView]; // 圣诞帽
    [self.filterView addSubview:self.faceWindow]; // 框脸用的
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // ...
        [self.videoCamera addTarget:self.filterView];
        [self.videoCamera startCameraCapture];

    });
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _hatOriginS = self.hatImageView.bounds.size;
    _filterViewS = self.filterView.bounds.size;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.filterView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
}

#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 限制人脸识别次数
    if ( ++_sampleCount % 3 != 0 ) {
        if ( _sampleCount > 99999 ) {
            _sampleCount = 0;
        }
        return;
    }
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    if (attachments) CFRelease(attachments);
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    // 按宽度比例来缩小图片，便于识别
    CGFloat factor = self->_filterViewS.width / clap.size.height;
    convertedImage = [convertedImage imageByApplyingTransform:CGAffineTransformMakeScale(factor, factor)];
    NSInteger factorH = clap.size.width * factor;
    [self beginDetectorFacewithImage:convertedImage afterRollingRect:CGRectMake(0, 0, self->_filterViewS.width, factorH)];
}

#pragma mark - ---------- Private Methods ----------
#pragma mark -开始人脸识别
- (void)beginDetectorFacewithImage:(CIImage *)image afterRollingRect:(CGRect)imageRect
{
    int exifOrientation = 6;
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    BOOL isUsingFrontFacingCamera = [self.videoCamera cameraPosition] != AVCaptureDevicePositionBack;
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown: {
            // Device oriented vertically, home button on the top
            exifOrientation = 8;
        } break;
            
        case UIDeviceOrientationLandscapeLeft: {
            // Device oriented horizontally, home button on the right
            if (isUsingFrontFacingCamera)
                exifOrientation = 3;
            else
                exifOrientation = 1;
        } break;
            
        case UIDeviceOrientationLandscapeRight: {
            // Device oriented horizontally, home button on the left
            if (isUsingFrontFacingCamera)
                exifOrientation = 1;
            else
                exifOrientation = 3;
        } break;
            
        case UIDeviceOrientationPortrait: {
            // Device oriented vertically, home button on the bottom
        }
            
        default: {
            exifOrientation = 6;
        } break;
    }
    
    // 获取人脸识别数据
    NSDictionary *opt = @{CIDetectorImageOrientation: @(exifOrientation)};
    NSArray *features = [self.faceDetector featuresInImage:image options:opt];
    
    // 分析人脸识别数据
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CIFaceFeature *faceFeature = [features lastObject];
        if ( faceFeature == nil ) {
            self.hatImageView.hidden == NO ? [self.hatImageView setHidden:YES] : nil;
            self.faceWindow.hidden == NO ? [self.faceWindow setHidden:YES] : nil;
        }
        else {
            self.hatImageView.hidden == YES ? [self.hatImageView setHidden:NO] : nil;
            self.faceWindow.hidden == YES ? [self.faceWindow setHidden:NO] : nil;
            
            CGRect faceR = [self faceRectForFaceFeature:faceFeature afterRollingRect:imageRect];
            
            // 预防抖动
            CGFloat offsetX = fabs(self.faceWindow.frame.origin.x - faceR.origin.x);
            CGFloat offsetY = fabs(self.faceWindow.frame.origin.y - faceR.origin.y);
            if ( offsetX < 8 && offsetY < 8 ) {
                return;
            }
            
            // 框脸
            self.faceWindow.frame = faceR;
            
            // 帽子
            CGFloat hatW = faceR.size.width * 1.3;
            CGFloat hatH = _hatOriginS.height * (hatW / _hatOriginS.width);
            CGFloat pX = faceR.origin.x + faceR.size.width * 0.5;
            CGFloat pY = faceR.origin.y - faceR.size.height * 0.45;

            // 帽子倾斜
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform = CGAffineTransformRotate(transform, ((faceFeature.faceAngle) / 180.0 * M_PI));
            [UIView animateWithDuration:0.2 animations:^{
                self.hatImageView.layer.affineTransform = transform;
                self.hatImageView.layer.bounds = CGRectMake(0, 0, hatW, hatH);
                self.hatImageView.layer.position = CGPointMake(pX, pY);
            }];
        }
    });
}

- (CGRect) faceRectForFaceFeature:(CIFaceFeature *)faceFeature afterRollingRect:(CGRect)imageRect
{
    // 计算画面与内容视图的偏差
    CGFloat lessH = self->_filterViewS.height - imageRect.size.height;
    CGFloat faceOffsetH = lessH * 0.5;
    
    // 摄像头的坐标 ==> 绘图坐标
    CGFloat faceW = faceFeature.bounds.size.height;
    CGFloat faceH = faceFeature.bounds.size.width;
    CGFloat faceX = faceFeature.bounds.origin.y;
    CGFloat faceY = faceFeature.bounds.origin.x + faceOffsetH;
    // 绘图坐标 ==> UI坐标
    return CGRectMake(self->_filterViewS.width - faceX - faceW, faceY, faceW, faceH);
}

#pragma mark - ---------- Event Methods ----------
- (void) exchangeCamera:(UIBarButtonItem *)item
{
    [self.videoCamera rotateCamera];
}

#pragma mark - ----------- Getter Methods ----------
- (CIDetector *)faceDetector
{
    if (_faceDetector == nil) {
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    }
    return _faceDetector;
}

- (GPUImageVideoCamera *)videoCamera
{
    if (_videoCamera == nil) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                           cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.frameRate = 24;
        _videoCamera.delegate = self;
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

- (UIImageView *)hatImageView
{
    if (_hatImageView == nil) {
        // 帽子视图
        _hatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"christmasHat"]];
        _hatImageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    }
    return _hatImageView;
}

- (UIImageView *)faceWindow
{
    if (_faceWindow == nil) {
        _faceWindow = [UIImageView new];
        _faceWindow.layer.borderWidth = 1;
        _faceWindow.layer.borderColor = [[UIColor redColor] CGColor];
    }
    return _faceWindow;
}

@end
