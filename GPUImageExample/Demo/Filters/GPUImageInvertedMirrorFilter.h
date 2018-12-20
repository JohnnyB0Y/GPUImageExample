//
//  GPUImageInvertedMirrorFilter.h
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/11.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//  倒影镜像

#import "GPUImageFilterGroup.h"
@class GPUImageVideoCamera;

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageInvertedMirrorFilter : GPUImageFilter

- (instancetype) initWithVideoCamera:(GPUImageVideoCamera *)camera;

@end

NS_ASSUME_NONNULL_END
