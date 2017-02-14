//
//  PinggaiView.m
//  DrawingRound
//
//  Created by apple on 2017/1/9.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "PinggaiView.h"
@interface PinggaiView ()<UIScrollViewDelegate>
{
    CGRect _frame;
}
@end
@implementation PinggaiView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _frame = frame;
        [self addScrollView];
        [self addPageControl];
    }
    return self;
}
//添加滚动视图
- (void)addScrollView {
    self.scrollView = [[UIScrollView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    //设置scrollView的contentSize属性
    self.scrollView.contentSize = CGSizeMake(4 * _frame.size.width, _frame.size.height);
    //设置scrollView按页滚动
    self.scrollView.pagingEnabled = YES;
    self.scrollView.scrollEnabled = NO;
    //将4张图片添加到scrollView上
    for (int i = 0; i < 4; i++) {
        UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"opern"]];
        imageView.frame = CGRectMake(i * _frame.size.width, 0, _frame.size.width, _frame.size.height);
        [self.scrollView addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        self.drawingV = [[DrawingView alloc]initWithFrame:imageView.bounds];
        [imageView addSubview:self.drawingV];
    }
    //将当前视图控制器设置成scrollView的代理人
    self.scrollView.delegate = self;
    //添加scrollView
    [self addSubview:self.scrollView];
}
//定义方法添加UIPageControl对象
- (void)addPageControl {
    //创建UIPageControl对象
    UIPageControl *pageControl = [[UIPageControl alloc]init];
    pageControl.backgroundColor = [UIColor cyanColor];
    pageControl.frame = CGRectMake(0, _frame.size.height - 50, _frame.size.width, 50);
    //设置pageControl当前的总页数
    pageControl.numberOfPages = 4;
    //将选中的页码设置为红色
    pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    //为pageControl添加响应事件
    [pageControl addTarget:self action:@selector(handlePageControlAction:) forControlEvents:UIControlEventValueChanged];
    //设置pageControl的tag
    pageControl.tag = 102;
    //添加pageControl对象
    [self addSubview:pageControl];
}
#pragma mark PageControl-Action
- (void)handlePageControlAction:(UIPageControl *)sender {
    [self.scrollView setContentOffset:CGPointMake(sender.currentPage * _frame.size.width, -64) animated:YES];
}
#pragma mark ScrollView Delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //获取scrollView的偏移量
    CGFloat offsetX = scrollView.contentOffset.x;
    //获取当前偏移的图片个数
    NSInteger count = offsetX / _frame.size.width;
    //获取指定的pageControl对象
    UIPageControl *pageControl = (UIPageControl *)[self viewWithTag:102];
    pageControl.currentPage = count;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
