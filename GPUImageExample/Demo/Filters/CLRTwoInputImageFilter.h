//
//  CLRTwoInputImageFilter.h
//  ImageEffect
//
//  Created by vk on 15/12/10.
//  Copyright © 2015年 clover. All rights reserved.
//

#import "GPUImage.h"

@interface CLRTwoInputImageFilter : GPUImageTwoInputFilter
{
    GLuint inputDataUniform;
    GLuint upDownUniform;
}

@property (nonatomic, assign) GLfloat inputData;

/** 控制红色素描是上面还是下面出现 */
@property (nonatomic, assign) GLfloat updown;

@end
