//
//  AGBreezeHUD.h
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

#import "AGProgressHUD.h"

NS_ASSUME_NONNULL_BEGIN

@interface AGBreezeHUD : AGProgressHUD

/** rotation left ? */
@property (nonatomic, assign, getter=isRotationToLeft) BOOL rotationToLeft;

@end

NS_ASSUME_NONNULL_END
