//
//  PictureViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/15.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "PictureViewController.h"
#import <GPUImage/GPUImage.h>
#import <Masonry.h>

@interface PictureViewController ()
<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong, nonatomic) GPUImageView *imageView; // 负责图片显示
@property (nonatomic, strong) GPUImageFilterPipeline *filterPipeline; // 负责滤镜组合
@property (nonatomic, strong) GPUImagePicture *imagePicture; // 负责图片处理

@property (nonatomic, strong) UIImagePickerController *picker;

@end

@implementation PictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"图片美化";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.imageView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"选图" style:UIBarButtonItemStyleDone target:self action:@selector(photoButtonClick:)];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
}

#pragma mark - 相册
- (void) photoButtonClick:(id)sender {
    
    [self presentViewController:self.picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo
{
    // 获取图片
    self.imagePicture = [[GPUImagePicture alloc] initWithImage:image];
    
    // 组合滤镜
    GPUImageToonFilter *toonFilter = [[GPUImageToonFilter alloc] init];
    GPUImageStretchDistortionFilter *stretchFilter = [[GPUImageStretchDistortionFilter alloc] init];
    
    self.filterPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:@[toonFilter, stretchFilter] input:self.imagePicture output:self.imageView];
    
    // 处理图片
    [self.imagePicture processImage];
    
    // 退出图片选择器
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//取消选取
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ----------- Getter Methods ----------
- (GPUImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[GPUImageView alloc] init];
    }
    return _imageView;
}

- (UIImagePickerController *)picker
{
    if (_picker == nil) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.allowsEditing = YES;
        _picker.delegate = self;
        _picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    return _picker;
}

@end
