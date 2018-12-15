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

@property (strong, nonatomic) UIImageView *imageView;

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
    self.imageView.image = image;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//取消选取
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ----------- Getter Methods ----------
- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
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
