//
//  GPUImageBeautyFilter.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/11.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "GPUImageBeautyFilter.h"
#import <GPUImage.h>

// Internal CombinationFilter(It should not be used outside)
@interface GPUImageCombinationFilter : GPUImageThreeInputFilter
{
    GLint smoothDegreeUniform;
}

@property (nonatomic, assign) CGFloat intensity;

@end

// 可以看到 SHADER_STRING 宏中包含着我们的 Shader (着色器)代码，我们的着色器字符串赋给一个 const NSString 对象（这个常量将在 GPUImageFilter 及其子类的初始化过程中用来设置 filter）。
NSString *const kGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 /**
  // varying 变量是Vertex 和 Fragment Shader（顶点着色器和片段着色器）之间做数据传递用的，一般 Vertex Shader（顶点着色器） 修改 varying 变量的值，然后 Fragment Shader（片段着色器）使用该varying变量的值。因此varying 变量在 Vertex 和 Fragment Shader 中声明必须一致。放到这里，也就是说 textureCoordinate 必须叫这个名字不能改。
  
  // highp 声明 textureCoordinate 精度（相应的还有mediump和lowp）。
  
  // vec2 声明textureCoordinate 文理坐标，是一个二维向量。
  
  // uniform 声明 inputImageTexture 是外部程序传递给 Shader 的变量， Shader 程序内部只能用，不能改。 sampler2D 声明变量是一个2D纹理。
  */
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 // Shader 从 main() 函数开始
 void main()
 {
     // texture2D 纹理取样器，根据纹理坐标返回纹理单元的值。
     // vec4 四维向量
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3,textureCoordinate3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     }
     else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     
     // gl_FragColor 是 Fragment Shader 预先定义的变量，赋给它的值就是该片段最终的颜色值。
     gl_FragColor = smooth;
 }
 );

@implementation GPUImageCombinationFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kGPUImageBeautifyFragmentShaderString]) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"]; // 光滑程度
    }
    self.intensity = 0.5;
    return self;
}

- (void)setIntensity:(CGFloat)intensity {
    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end


@interface GPUImageBeautyFilter ()

@end

@implementation GPUImageBeautyFilter {
    GPUImageBilateralFilter *_bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *_cannyEdgeFilter;
    GPUImageHSBFilter *_hsbFilter;
    GPUImageCombinationFilter *_combinationFilter;
}

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // First pass: face smoothing filter
    _bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    _bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:_bilateralFilter];
    
    // Second pass: edge detection
    _cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:_cannyEdgeFilter];
    
    // Third pass: combination bilateral, edge detection and origin
    _combinationFilter = [[GPUImageCombinationFilter alloc] init];
    [self addFilter:_combinationFilter];
    
    // Adjust HSB
    _hsbFilter = [[GPUImageHSBFilter alloc] init];
    [_hsbFilter adjustBrightness:1.1]; // 亮度
    [_hsbFilter adjustSaturation:1.1]; // 饱和度
    
    [_bilateralFilter addTarget:_combinationFilter]; // _bilateralFilter 绘制完，通知 _combinationFilter。
    [_cannyEdgeFilter addTarget:_combinationFilter]; // _cannyEdgeFilter 绘制完，通知 _combinationFilter。
    
    
    /**
     GPUImageCombinationFilter判断是否有三个纹理，三个纹理都已经准备好后
     调用GPUImageThreeInputFilter的绘制函数renderToTextureWithVertices: textureCoordinates:，
     图像绘制完后，把图像设置为GPUImageHSBFilter的输入纹理,
     通知GPUImageHSBFilter纹理已经绘制完毕；
     */
    [_combinationFilter addTarget:_hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:_bilateralFilter,
                           _cannyEdgeFilter,
                           _combinationFilter, nil];
    
    self.terminalFilter = _hsbFilter;
    
    return self;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            if (currentFilter == _combinationFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter == _combinationFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end
