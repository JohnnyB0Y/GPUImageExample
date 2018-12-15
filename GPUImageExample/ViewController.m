//
//  ViewController.m
//  GPUImageExample
//
//  Created by JohnnyB0Y on 2018/12/11.
//  Copyright © 2018 JohnnyB0Y. All rights reserved.
//

#import "ViewController.h"
#import "Demo/BeautyViewController.h"
#import "Demo/FaceViewController.h"
#import "Demo/PictureViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    NSArray *_items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _items = @[@"人脸识别", @"美颜相机", @"图片美化"];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellID];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:24];
    }
    
    NSString *title = _items[indexPath.row];
    cell.textLabel.text = title;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 124.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 124.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UIViewController *targetVC;
    if ( indexPath.row == 0 ) {
        targetVC = [[FaceViewController alloc] init];
    }
    else if ( indexPath.row == 1 ) {
        // 美颜相机
        targetVC = [[BeautyViewController alloc] init];
        
    }
    else if ( indexPath.row == 2 ) {
        // 图片美化
        targetVC = [[PictureViewController alloc] init];
    }
    
    if ( targetVC ) {
        [self.navigationController pushViewController:targetVC animated:YES];
    }
}

@end
