//
//  GPUImageInvertedMirrorFilter.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/11.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "GPUImageInvertedMirrorFilter.h"
#import <AGCategories/UIImage+AGTransform.h>
#import <GPUImage.h>


@interface GPUImageInvertedMirrorFilter ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, GPUImageFramebuffer *> *indexToFrameBufferDict;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSValue *> *indexToDrawRectDict;
@property (nonatomic, assign) NSInteger mainFilterIndex;
@property (nonatomic, assign) NSInteger maxFilterIndex;
@property (nonatomic, assign) NSInteger curFilterIndex;

@end

@implementation GPUImageInvertedMirrorFilter {
    __weak GPUImageVideoCamera *_videoCamera;
}

#pragma mark - ----------- Life Cycle ----------
- (instancetype)initWithVideoCamera:(GPUImageVideoCamera *)camera
{
    self = [self initWithFragmentShaderFromString:kGPUImagePassthroughFragmentShaderString];
    if ( ! self ) return nil;
    
    // 1. 初始化
    NSInteger maxFilter = 4;
    self->_videoCamera = camera;
    self.maxFilterIndex = maxFilter;
    self.curFilterIndex = 0;
    self.mainFilterIndex = 0;
    self.indexToFrameBufferDict = [[NSMutableDictionary alloc] init];
    self.indexToDrawRectDict = [[NSMutableDictionary alloc] init];
    
    // 2. 您可以将变换设置为二维仿射变换或三维变换。默认情况下是标识转换(输出图像与输入图像相同)。
    NSInteger maxColumn = 2;
    NSInteger maxRow = 2;
    for ( NSInteger i = 0; i<maxFilter; i++ ) {
        // 计算 视频区域大小
        NSInteger col = i % maxColumn;
        NSInteger row = i / maxRow;
        // 屏幕宽度为 1，高度为1；
        CGRect frame = CGRectMake(col * 0.5, row * 0.5, 0.5, 0.5);
        
        // 指定视频播放源
        CGAffineTransform transform = CGAffineTransformIdentity;
        if ( frame.origin.x == 0 && frame.origin.y > 0 ) {
            // 第三个视频
            transform = CGAffineTransformMakeScale(1, -1);
        }
        else if ( frame.origin.x > 0 ) {
            
            if ( frame.origin.y > 0 ) {
                // 第四个视频
                transform = CGAffineTransformMakeScale(-1, -1);
            }
            else {
                // 第二个视频
                transform = CGAffineTransformMakeScale(-1, 1);
            }
        }
        [self _addNewScreen:frame transform:transform];
    }
    
    return self;
}

- (void) _addNewScreen:(CGRect)frame transform:(CGAffineTransform)transform
{
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    if ( CGAffineTransformIsIdentity(transform) == NO ) {
        transformFilter.affineTransform = transform;
    }
    
    [_videoCamera addTarget:transformFilter];
    
    NSInteger index = [self nextAvailableTextureIndex];
    [transformFilter addTarget:self atTextureLocation:index];
    
    // 存储 绘制坐标
    self.indexToDrawRectDict[@(index)] = [NSValue valueWithCGRect:frame];
}

#pragma mark 下一个有效的纹理 Index
- (NSInteger)nextAvailableTextureIndex {
    NSInteger ret = 0;
    if (self.curFilterIndex < self.maxFilterIndex) {
        ret = self.curFilterIndex++;
    }
    else {
        NSAssert(NO, @"should not call，too much index");
    }
    return ret;
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)filterIndex {
    self.indexToFrameBufferDict[@(filterIndex)] = newInputFramebuffer;
    [newInputFramebuffer lock];
}

#pragma mark 新的帧准备好了
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)filterIndex {
    
    if (self.indexToDrawRectDict[@(filterIndex)]) {
        CGRect rect = [self.indexToDrawRectDict[@(filterIndex)] CGRectValue];
        
        // 计算 顶点着色器 位置信息
        GLfloat vertices[] = {
            rect.origin.x * 2 - 1, rect.origin.y * 2 - 1, // 左下
            rect.origin.x * 2 - 1 + rect.size.width * 2, rect.origin.y * 2 - 1,// 右下
            rect.origin.x * 2 - 1, rect.origin.y * 2 - 1 + rect.size.height * 2, // 左上
            rect.origin.x * 2 - 1 + rect.size.width * 2, rect.origin.y * 2 - 1 + rect.size.height * 2,  // 右上
        };
        
        // 渲染 顶点着色器；纹理坐标
        [self _renderToTextureWithVertices:vertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] atIndex:filterIndex];
        
        
        if (filterIndex == self.mainFilterIndex) {
            // 告知 targets们关于下一帧
            [self informTargetsAboutNewFrameAtTime:frameTime];
        }
    }
    else {
        NSAssert(NO, @"error empty draw rect");
    }
}

#pragma mark 告知 targets们关于下一帧
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime
{
    if (self.frameProcessingCompletionBlock != NULL)
    {
        // 帧处理完成调用
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        // 通知检测的对象
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
        }
    }
    
    // 解锁
    [[self framebufferForOutput] unlock];
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            // 通知他的朋友们
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

#pragma mark - ---------- Private Methods ----------
#pragma mark 绘制相关
- (void) _renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates atIndex:(NSInteger)filterIndex {
    GPUImageFramebuffer *frameBuffer;
    if (self.indexToFrameBufferDict[@(filterIndex)]) {
        frameBuffer = self.indexToFrameBufferDict[@(filterIndex)];
    }
    else {
        NSLog(@"lytest: not ready at index: %ld", filterIndex);
        return ;
    }
    
    if (self.preventRendering)
    {
        [frameBuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    if (!outputFramebuffer) {
        // 没有输出帧缓存时
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    else {
        // 有输出帧缓存时，加锁
        [outputFramebuffer lock];
    }
    // 激活
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:filterIndex];
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [frameBuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    // 绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [frameBuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

#pragma mark 释放资源
- (void)dealloc {
    if (outputFramebuffer) {
        [outputFramebuffer unlock]; // 因为取消了unlock
        outputFramebuffer = nil;
    }
}

//- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex
//{
//    // origin
//    CGImageRef imageRef = [newInputFramebuffer newCGImageFromFramebufferContents];
//
//    if ( imageRef == nil ) {
//        return;
//    }
//    // .........
//    UIImage *img = [UIImage imageNamed:@"christmasHat"];
//    CGImageRef newImageRef = [self newCGImagePinWithCGImage:img.CGImage];
//
//    UIImage *image = [UIImage imageWithCGImage:newImageRef];
//    GLuint texName = [self textureFromImage:image];
    
//    CGFloat width = CGImageGetWidth(newImageRef);
//    CGFloat height = CGImageGetHeight(newImageRef);
//
//    /** 把iOS中的UIImage轉換為OpenGL ES中的texture數據。 */
//    GLubyte *textureData        = (GLubyte *)malloc(width * height * 4);
//    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
//
//    NSUInteger bytesPerPixel    = 4;
//    NSUInteger bytesPerRow      = bytesPerPixel * width;
//    NSUInteger bitsPerComponent = 8;
//
//    CGContextRef context = CGBitmapContextCreate(textureData,
//                                                 width,
//                                                 height,
//                                                 bitsPerComponent,
//                                                 bytesPerRow,
//                                                 colorSpace,
//                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);
//
//    glEnable(GL_TEXTURE_2D);
//    GLuint texName;
//    glGenTextures(1, &texName);
//    glBindTexture(GL_TEXTURE_2D, texName);
//
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    glTexImage2D(GL_TEXTURE_2D,
//                 0,
//                 GL_RGBA,
//                 (GLsizei)width,
//                 (GLsizei)height,
//                 0,
//                 GL_RGBA,
//                 GL_UNSIGNED_BYTE,
//                 textureData);
//
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//    free(textureData);
    
//    GPUImageFramebuffer *f = [[GPUImageFramebuffer alloc] initWithSize:newInputFramebuffer.size overriddenTexture:texName];
//
//
//    firstInputFramebuffer = f;
//    [firstInputFramebuffer lock];
//
//    //[self useNextFrameForImageCapture];
//
//    // 释放资源
//    CFRelease(imageRef);
//    CFRelease(newImageRef);
//    UIGraphicsEndImageContext();
//}

/**
 截取图像的一个区域重绘图像
 CGImageRef CGImageCreateWithImageInRect(CGImageRef image, CGRect rect)
 

 */


@end
