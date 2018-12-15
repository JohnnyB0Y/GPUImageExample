//
//  AGPopupManager.m
//  AGPopupVC
//
//  Created by JohnnyB0Y on 2017/3/7.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//  警告框

#import "AGPopupManager.h"

@interface __AGAlertController : UIAlertController
/** alertTag */
@property (nonatomic, strong) NSNumber *alertTag;
@end

@interface AGPopupManager ()
<
UIAlertViewDelegate
>

/** 缓存 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id> *blockDictM;

@end

@implementation AGPopupManager {
    NSInteger _alertTag;
}

+ (instancetype) sharedInstance
{
    static AGPopupManager *popupManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        popupManager = [[self alloc] init];
        popupManager->_alertTag = 1024;
        popupManager->_blockDictM = [NSMutableDictionary dictionaryWithCapacity:8];
    });
    return popupManager;
}

#pragma mark - ---------- System Delegate ----------
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSNumber *tag = @(alertView.tag);
    AlertOperationBlock block = self.blockDictM[tag];
    
    if (block) {
        block(alertView, buttonIndex);
        
        // 执行完，移除代码块
        [self.blockDictM removeObjectForKey:tag];
    }
}
#pragma clang diagnostic pop

#pragma mark - ---------- Public Methods ----------
- (void) ag_showAlertView:(AlertSetupBlock)setupBlock
                    title:(NSString *)title
                  message:(NSString *)message
          operationBlocks:(AlertOperationBlock)operationBlocks
        cancelButtonTitle:(NSString *)cancelButtonTitle
        otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    // 取出可变参数
    va_list args;
    va_start(args, otherButtonTitles);
    NSMutableArray *buttonTitlesArray = [NSMutableArray new];
    while (otherButtonTitles != nil) {
        [buttonTitlesArray addObject:otherButtonTitles];
        otherButtonTitles = va_arg(args, NSString *);
    }
    va_end(args);
    
    [[self _createAlertView:setupBlock
                      title:title
                    message:message
            operationBlocks:operationBlocks
          cancelButtonTitle:cancelButtonTitle
          otherButtonTitles:buttonTitlesArray] show];
}

- (void)ag_showAlertViewWithTitle:(NSString *)title
                          message:(NSString *)message
                  operationBlocks:(AlertOperationBlock)operationBlocks
                cancelButtonTitle:(NSString *)cancelButtonTitle
                otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    // 取出可变参数
    va_list args;
    va_start(args, otherButtonTitles);
    NSMutableArray *buttonTitlesArray = [NSMutableArray new];
    while (otherButtonTitles != nil) {
        [buttonTitlesArray addObject:otherButtonTitles];
        otherButtonTitles = va_arg(args, NSString *);
    }
    va_end(args);
    
    [[self _createAlertView:nil
                      title:title
                    message:message
            operationBlocks:operationBlocks
          cancelButtonTitle:cancelButtonTitle
          otherButtonTitles:buttonTitlesArray] show];
}

- (UIAlertController *) ag_actionSheetWithTitle:(NSString *)title
                                        message:(NSString *)message
                                    cancelTitle:(NSString *)cancelTitle
                               destructiveTitle:(NSString *)destructiveTitle
                                operationBlocks:(AlertCOperationBlock)operationBlocks
{
    return [self ag_actionSheetWithTitle:title
                                 message:message
                             cancelTitle:cancelTitle
                       alertActionTitles:@[AASDestructive(destructiveTitle)]
                         operationBlocks:operationBlocks];
}

- (UIAlertController *) ag_actionSheetWithTitle:(NSString *)title
                                        message:(NSString *)message
                                    cancelTitle:(NSString *)cancelTitle
                              alertActionTitles:(NSArray<NSDictionary *> *)alertActionTitles
                                operationBlocks:(AlertCOperationBlock)operationBlocks
{
    return [self ag_alertController:nil
                              title:title
                            message:message
                     preferredStyle:UIAlertControllerStyleActionSheet
                        cancelTitle:cancelTitle alertActionTitles:alertActionTitles
                    operationBlocks:operationBlocks];
}

- (UIAlertController *) ag_alertController:(AlertCSetupBlock)setupBlock
                                     title:(NSString *)title
                                   message:(NSString *)message
                               cancelTitle:(NSString *)cancelTitle
                          destructiveTitle:(NSString *)destructiveTitle
                           operationBlocks:(AlertCOperationBlock)operationBlocks
{
    return [self ag_alertController:setupBlock
                              title:title
                            message:message
                     preferredStyle:UIAlertControllerStyleAlert
                        cancelTitle:cancelTitle
                  alertActionTitles:@[AASDestructive(destructiveTitle)]
                    operationBlocks:operationBlocks];
}

- (UIAlertController *) ag_alertController:(AlertCSetupBlock)setupBlock
                                     title:(NSString *)title
                                   message:(NSString *)message
                            preferredStyle:(UIAlertControllerStyle)preferredStyle
                               cancelTitle:(NSString *)cancelTitle
                         alertActionTitles:(NSArray<NSDictionary *> *)alertActionTitles
                           operationBlocks:(AlertCOperationBlock)operationBlocks
{
    // 创建
    __AGAlertController *alertC =
    [__AGAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:preferredStyle];
    
    // 设置属性
    if (setupBlock) {
        setupBlock(alertC);
    }
    
    // 添加按钮
    for ( NSInteger i = 0; i < alertActionTitles.count; i++ ) {
        NSDictionary *alertActionDict = [alertActionTitles objectAtIndex:i];
        
        [alertC addAction:[self _alertActionWithAlertC:alertC AlertActionDict:alertActionDict atIndex:i+1]];
    }
    
    // 添加取消按钮
    if ( cancelTitle ) {
        [alertC addAction:[self _alertActionWithAlertC:alertC AlertActionDict:[AGPopupManager alertActionStyleCancel:cancelTitle] atIndex:0]];
    }
    
    // 保存block
    NSNumber *key = [self _newAlertTag];
    alertC.alertTag = key;
    
    if (operationBlocks) {
        [self.blockDictM setObject:[operationBlocks copy] forKey:key];
    }
    
    return alertC;
}

#pragma mark - ---------- Private Methods ----------
#pragma mark 生成新的 tag
- (NSNumber *) _newAlertTag
{
    return @(++_alertTag);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (UIAlertView *) _createAlertView:(AlertSetupBlock)setupBlock
                             title:(NSString *)title
                           message:(NSString *)message
                   operationBlocks:(AlertOperationBlock)operationBlocks
                 cancelButtonTitle:(NSString *)cancelButtonTitle
                 otherButtonTitles:(NSArray<NSString *> *)otherButtonTitles
{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.title = title;
    alertView.message = message;
    alertView.delegate = self;
    
    // 添加按钮
    if (cancelButtonTitle) {
        [alertView addButtonWithTitle:cancelButtonTitle];
    }
    
    for (NSString *otherBtnTitle in otherButtonTitles) {
        [alertView addButtonWithTitle:otherBtnTitle];
    }
    
    // 保存block
    NSNumber *key = [self _newAlertTag];
    alertView.tag = key.integerValue;
    
    if (operationBlocks) {
        [self.blockDictM setObject:[operationBlocks copy] forKey:key];
    }
    
    // 设置属性
    if (setupBlock) {
        setupBlock(alertView);
    }
    
    return alertView;
}
#pragma clang diagnostic pop


- (UIAlertAction *) _alertActionWithAlertC:(__AGAlertController *)alertC AlertActionDict:(NSDictionary *)alertActionDict atIndex:(NSInteger)index
{
    __weak __AGAlertController *weakAlertC = alertC;
    __weak typeof(self) weakSelf = self;
    
    NSString *actionStyleStr = [[alertActionDict allKeys] lastObject];
    UIAlertActionStyle actionStyle = [actionStyleStr integerValue];
    NSString *title = [alertActionDict objectForKey:actionStyleStr];
    
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:actionStyle handler:^(UIAlertAction * _Nonnull action) {
        
        __strong __AGAlertController *strongAlertC = weakAlertC;
        
        // 处理事件
        if ( strongAlertC ) {
            AlertCOperationBlock block = weakSelf.blockDictM[strongAlertC.alertTag];
            
            if (block) {
                block(strongAlertC, index);
            }
        }
        
    }];
    
    return alertAction;
}

#pragma mark UIAlertController 包装 alertAction 按钮的标题和类型
+ (NSDictionary *) alertActionStyleDefault:(NSString *)title
{
    return @{@(UIAlertActionStyleDefault).stringValue : title};
}

+ (NSDictionary *) alertActionStyleCancel:(NSString *)title
{
    return @{@(UIAlertActionStyleCancel).stringValue : title};
}

+ (NSDictionary *) alertActionStyleDestructive:(NSString *)title
{
    return @{@(UIAlertActionStyleDestructive).stringValue : title};
}

#pragma mark - ---------- Getter Methods ----------

#pragma mark -
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.blockDictM];
}

@end


@implementation __AGAlertController

- (void)dealloc
{
    if (self.alertTag) {
        [[[AGPopupManager sharedInstance] blockDictM] removeObjectForKey:self.alertTag];
    }
}

@end
