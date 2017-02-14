//
//  ViewController.m
//  Drawing
//
//  Created by apple on 2017/2/14.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ViewController.h"
#import "PinggaiView.h"
#define Width [UIScreen mainScreen].bounds.size.width
#define Height [UIScreen mainScreen].bounds.size.height
@interface ViewController ()
@property (nonatomic, strong)PinggaiView *PinggaiV;
@property (nonatomic, assign)BOOL annotationMode;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"批注模式" style:UIBarButtonItemStyleDone target:self action:@selector(handleLeftBarButtonAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"查看结果" style:UIBarButtonItemStyleDone target:self action:@selector(handleSeeDrawingAction)];
    self.PinggaiV = [[PinggaiView alloc]initWithFrame:CGRectMake(0, 0, Width, Height - 64)];
    [self.view addSubview:self.PinggaiV];
    
}
//
- (void)handleSeeDrawingAction {
    
}
- (void)handleLeftBarButtonAction {
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
