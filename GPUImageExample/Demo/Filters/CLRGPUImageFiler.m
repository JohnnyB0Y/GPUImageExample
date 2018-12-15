//
//  CLRGPUImageFiler.m
//  ImageEffect
//
//  Created by vk on 15/12/10.
//  Copyright © 2015年 clover. All rights reserved.
//

#import "CLRGPUImageFiler.h"
#import "CLRTwoInputImageFilter.h"

@interface CLRGPUImageFiler()

@property (nonatomic, strong) GPUImageCannyEdgeDetectionFilter *cannyFilter;
@property (nonatomic, strong) CLRTwoInputImageFilter *clrTwoFilter;
@property (nonatomic, strong) GPUImageDilationFilter *dilationFilter;

@end

@implementation CLRGPUImageFiler

- (id)init
{
    if(self = [super init]) {
        _cannyFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        _dilationFilter = [[GPUImageDilationFilter alloc] initWithRadius:2];
        [_cannyFilter addTarget:_dilationFilter];
        
        _clrTwoFilter =  [[CLRTwoInputImageFilter alloc] init];
        
        
        [_dilationFilter addTarget:_clrTwoFilter atTextureLocation:1];
        
        
        [self addFilter:_cannyFilter];
        [self addFilter:_clrTwoFilter];
        
        
        self.initialFilters = [NSArray arrayWithObjects:_cannyFilter, _clrTwoFilter, nil];
        self.terminalFilter = _clrTwoFilter;
    }
    
    return self;
}

- (void)setInputData:(GLfloat)inputData {
    _inputData = inputData;
    _clrTwoFilter.inputData = _inputData;
}

- (void)setUpDown:(GLfloat)upDown {
    _upDown = upDown;
    _clrTwoFilter.updown = _upDown;
}

@end
