//
//  OpenGLViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/16.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "OpenGLViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>
#import "NSObject+CoordinateTransformation.h"
#import "../../Helper/ZQLShaderCompiler.h"
#import <AGCategories/UIImage+AGTransform.h>

@interface OpenGLViewController ()
{
    EAGLContext *_eaglContext;
    CAEAGLLayer *_eaglLayer;
    
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
    GLuint _textureSlot;
    GLuint _textureCoordSlot;
    GLuint _colorSlot;
    
    ZQLShaderCompiler *shaderCompiler;
}

/** image */
@property (nonatomic, strong) UIImage *image;

@end

@implementation OpenGLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupOpenGLContext];
    [self setupCAEAGLLayer:self.view.bounds];
    [self clearRenderBuffers];
    [self setupRenderBuffers];
    [self setupViewPort];
    [self setupShader];
    
    //[self drawTrangle];
    
    [self drawImage];
}

#pragma mark - ---------- Private Methods ----------
- (GLuint)textureFromImage:(UIImage *)image
{
    /** 把iOS中的UIImage轉換為OpenGL ES中的texture數據。 */
    CGImageRef imageRef = [image CGImage];
    size_t w = CGImageGetWidth (imageRef);
    size_t h = CGImageGetHeight(imageRef);
    
    GLubyte *textureData        = (GLubyte *)malloc(w * h * 4);
    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel    = 4;
    NSUInteger bytesPerRow      = bytesPerPixel * w;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(textureData,
                                                 w,
                                                 h,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, h);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), imageRef);
    
    glEnable(GL_TEXTURE_2D);
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 (GLsizei)w,
                 (GLsizei)h,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 textureData);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(textureData);
    
    return texName;
}

#pragma mark - Setup GL ES

// step1
- (void)setupOpenGLContext {
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //opengl es 2.0
    [EAGLContext setCurrentContext:_eaglContext]; //设置为当前上下文。
}

// step2
- (void)setupCAEAGLLayer:(CGRect)rect {
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = rect;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:_eaglLayer];
}

// step3
- (void)clearRenderBuffers {
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
}

// step4
- (void)setupRenderBuffers {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    GLint width = 0;
    GLint height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

// step6
- (void)setupViewPort {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

// step7
- (void)setupShader {
    shaderCompiler = [[ZQLShaderCompiler alloc] initWithVertexShader:@"copyImage.vsh" fragmentShader:@"copyImage.fsh"];
    [shaderCompiler prepareToDraw];
    _positionSlot = [shaderCompiler attributeIndex:@"a_Position"];
    _textureSlot = [shaderCompiler uniformIndex:@"u_Texture"];
    _textureCoordSlot = [shaderCompiler attributeIndex:@"a_TexCoordIn"];
    _colorSlot = [shaderCompiler attributeIndex:@"a_Color"];
}

// step8
- (void)drawTrangle {
    // 根据OpenGL ES的坐标系，确定了三角形的三个顶点，然后生成了一个一维数组，用来存放三个顶点的坐标。
    static const GLfloat vertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1, 1,  0};   //左上
    // 激活了在vertex shader中声明的a_Position这个变量。
    glEnableVertexAttribArray(_positionSlot);
    
    // 将我们的vertices数组赋值给vertex shader中的a_Position.
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    // 6个顶点
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    
    
    /**
     void glVertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,const GLvoid * pointer);
     
     第一个,index.
     这个值是索引。哪里的索引呢？其实，索引，指的就是shader中，某个变量的位置。这里，自然传入的就是a_Position这个变量的位置了。
     
     第二个，size。
     是指，传入某个变量的数量，更简单地说，就是vec多少， 比如，位置，就是3，xyz，颜色就是4，rgba.这里你可能会有疑问，为啥shader里声明的a_Position是vec4，但是在vertices中，每个位置我们只用了3个数值来表示，还有一个呢？你疑惑的没错，其实位置是vec4(x,y,z,w)，但是最后一个w只有在矩阵变换的时候才有用，默认情况下是1.在这里我们不需要传入w。所以位置信息是3.
     
     第三个，type
     指定数组中每个组件的数据类型。我们用的是float类型，所以是GL_Float。
     
     第四个， normalized
     指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
     
     第五个， stride
     指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0。
     在这里，我们传递的是数组不是一个struct类型，所以是0，这块内容后面还会详细介绍。
     
     第六个，pointer
     指定第一个组件在数组的第一个顶点属性中的偏移量。该数组与GL_ARRAY_BUFFER绑定，储存于缓冲区中。初始值为0，也可以直接传递顶点数组，也就是我们的vertices
     
     */
    
}

//
- (void)activeTexture {
    
    GLuint texName = [self textureFromImage:self.image];
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, texName);
    glUniform1i(_textureSlot, 5);
    
}

- (void)drawImage {
    [self activeTexture];
    
    UIImage *image = self.image;
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.view.bounds);
    CGFloat widthRatio = realRect.size.width/self.view.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.view.bounds.size.height;
    
    const GLfloat vertices[] = {
        -widthRatio, -heightRatio, 0,   //左下
        widthRatio,  -heightRatio, 0,   //右下
        -widthRatio, heightRatio,  0,   //左上
        widthRatio,  heightRatio,  0 }; //右上
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    // normal
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    glEnableVertexAttribArray(_textureCoordSlot);
    glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, coords);
    
    static const GLfloat colors[] = {
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1
    };
    
    glEnableVertexAttribArray(_colorSlot);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - ----------- Getter Methods ----------
- (UIImage *)image
{
    if (_image == nil) {
        UIImage *image = [UIImage imageNamed:@"christmasHat"];
        
        CGSize originSize = image.size;
        
        CGSize size;
        size.width = image.size.width * 2;
        size.height = image.size.height * 2;
        
        UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
        
        UIImage *hImage = [image ag_imageFlipHorizontal];
        [image drawInRect:CGRectMake(0, 0, originSize.width, originSize.height)];
        [hImage drawInRect:CGRectMake(originSize.width, 0, originSize.width, originSize.height)];
        
        // 翻转
        UIImage *downImage = [image ag_imageRotate:UIImageOrientationDown];
        UIImage *hDownImage = [downImage ag_imageFlipHorizontal];
        
        [hDownImage drawInRect:CGRectMake(0, originSize.height, originSize.width, originSize.height)];
        [downImage drawInRect:CGRectMake(originSize.width, originSize.height, originSize.width, originSize.height)];
        
        _image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    return _image;
}

@end
