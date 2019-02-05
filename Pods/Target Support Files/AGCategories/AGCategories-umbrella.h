#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AGCategories.h"
#import "NSBundle+AGSupportCocoapods.h"
#import "NSDate+AGGenerate.h"
#import "NSFileManager+AGFolderOperation.h"
#import "NSFileManager+AGFolderPath.h"
#import "NSString+AGJudge.h"
#import "UIColor+AGExtensions.h"
#import "UIImage+AGGenerate.h"
#import "UIImage+AGTransform.h"

FOUNDATION_EXPORT double AGCategoriesVersionNumber;
FOUNDATION_EXPORT const unsigned char AGCategoriesVersionString[];

