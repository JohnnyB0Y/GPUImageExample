//
//  AGPopupManager.h
//  AGPopupVC
//
//  Created by JohnnyB0Y on 2017/3/7.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//  警告框

#import <UIKit/UIKit.h>

// UIAlertController 包装 alertAction 按钮的标题和类型
#define AASDefault(title) [AGPopupManager alertActionStyleDefault:title]
#define AASDestructive(title) [AGPopupManager alertActionStyleDestructive:title]

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
/** 点击处理 UIAlertView block */
typedef void (^AlertOperationBlock)(UIAlertView *alertView, NSInteger clickedIndex);
/** 设置属性 UIAlertView block */
typedef void (^AlertSetupBlock)(UIAlertView *alertView);
#pragma clang diagnostic pop

/** 点击处理 UIAlertController block */
typedef void (^AlertCOperationBlock)(UIAlertController *alertC, NSInteger clickedIndex);
/** 设置属性 UIAlertController block */
typedef void (^AlertCSetupBlock)(UIAlertController *alertC);


@interface AGPopupManager : NSObject

+ (instancetype) sharedInstance;

/**
 * iOS 7 弹出 UIAlertView
 *
 * setupBlock ：show alertView 前调用的block
 * title ：alertView 标题
 * message ：alertView 信息
 * operationBlocks alertView 点击处理的block
 * cancelButtonTitle ：取消按钮标题
 * otherButtonTitles：其他按钮的标题s
 */
- (void) ag_showAlertView:(AlertSetupBlock)setupBlock
                    title:(NSString *)title
                  message:(NSString *)message
          operationBlocks:(AlertOperationBlock)operationBlocks
        cancelButtonTitle:(NSString *)cancelButtonTitle
        otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * iOS 7 弹出 UIAlertView
 *
 * title ：alertView 标题
 * message ：alertView 信息
 * operationBlocks alertView 点击处理的block
 * cancelButtonTitle ：取消按钮标题
 * otherButtonTitles：其他按钮的标题s
 */
- (void) ag_showAlertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                   operationBlocks:(AlertOperationBlock)operationBlocks
                 cancelButtonTitle:(NSString *)cancelButtonTitle
                 otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
 iOS 8 或以上，弹出 ActionSheet
 
 @param title 弹窗标题
 @param message 弹窗信息
 @param cancelTitle 取消按钮标题
 @param destructiveTitle 确认按钮标题
 @param operationBlocks 点击后处理的 Block
 @return alertController
 */
- (UIAlertController *) ag_actionSheetWithTitle:(NSString *)title
                                        message:(NSString *)message
                                    cancelTitle:(NSString *)cancelTitle
                               destructiveTitle:(NSString *)destructiveTitle
                                operationBlocks:(AlertCOperationBlock)operationBlocks;

/**
 iOS 8 或以上，弹出 ActionSheet
 
 @param title 弹窗标题
 @param message 弹窗信息
 @param cancelTitle 取消按钮标题
 @param alertActionTitles 其他按钮标题样式 @[AASDefault(@"默认"), AASDestructive(@"确定")]
 @param operationBlocks 点击后处理的 Block
 @return alertController
 */
- (UIAlertController *) ag_actionSheetWithTitle:(NSString *)title
                                        message:(NSString *)message
                                    cancelTitle:(NSString *)cancelTitle
                              alertActionTitles:(NSArray<NSDictionary *> *)alertActionTitles
                                operationBlocks:(AlertCOperationBlock)operationBlocks;

/**
 iOS 8 或以上，弹出 AlertView
 
 @param setupBlock 对 alertController 额外处理的 Block
 @param title 弹窗标题
 @param message 弹窗信息
 @param cancelTitle 取消按钮标题
 @param destructiveTitle 确认按钮标题
 @param operationBlocks 点击后处理的 Block
 @return alertController
 */
- (UIAlertController *) ag_alertController:(AlertCSetupBlock)setupBlock
                                     title:(NSString *)title
                                   message:(NSString *)message
                               cancelTitle:(NSString *)cancelTitle
                          destructiveTitle:(NSString *)destructiveTitle
                           operationBlocks:(AlertCOperationBlock)operationBlocks;


/**
 iOS 8 或以上，弹出 AlertView & ActionSheet

 @param setupBlock 对 alertController 额外处理的 Block
 @param title 弹窗标题
 @param message 弹窗信息
 @param preferredStyle 弹窗样式 AlertView & ActionSheet
 @param cancelTitle 取消按钮标题
 @param alertActionTitles 其他按钮标题样式 @[AASDefault(@"默认"), AASDestructive(@"确定")]
 @param operationBlocks 点击后处理的 Block
 @return alertController
 */
- (UIAlertController *) ag_alertController:(AlertCSetupBlock)setupBlock
                                     title:(NSString *)title
                                   message:(NSString *)message
                            preferredStyle:(UIAlertControllerStyle)preferredStyle
                               cancelTitle:(NSString *)cancelTitle
                         alertActionTitles:(NSArray<NSDictionary *> *)alertActionTitles
                           operationBlocks:(AlertCOperationBlock)operationBlocks;

#pragma mark UIAlertController 包装 alertAction 按钮的标题和类型 @{@"1" : title}
+ (NSDictionary *) alertActionStyleDefault:(NSString *)title;
+ (NSDictionary *) alertActionStyleDestructive:(NSString *)title;

@end
