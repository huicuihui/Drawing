//
//  DrawingView.m
//  DrawingRound
//
//  Created by apple on 2016/12/7.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "DrawingView.h"
#import "DrawingTool.h"
#define kDefaultLineColor       [UIColor blackColor]
#define kDefaultLineWidth       5.0f
#define kDefaultLineAlpha       1.0f
#define kSelectedLineColor      [UIColor cyanColor]

static const double MarkClickSize = 5.0;    //标注的边缘点击响应区域大小
static const float MARK_CIRCLE_SIZE = 10;   //批注的四个边角圆形大小


typedef NS_ENUM(NSUInteger, TouchType)
{
    NEW_MARK,           //按下去的动作是新建批注
    SELECT_MARK,        //按下去的动作是选中一个未被选中的批注
    UNSELECT_MARK,      //按下去的动作是选中一个已被选中的批注
    RESIZE_MARK         //按下去的动作是编辑已被选中的批注
};
typedef NS_ENUM(NSUInteger, TouchDirection)
{
    Left_Top,           //左上角
    Right_Top,          //右上角
    Left_Bottom,        //左下角
    Right_Bottom        //右下角
};
// experimental code

@interface DrawingView ()
@property (nonatomic, strong)NSMutableArray *bufferArray;
@property (nonatomic, strong)DrawingTool *currentTool;

@property (nonatomic, strong)UIImage *image;

@property (nonatomic, assign)CGPoint firstPoint;
@property (nonatomic, assign)CGPoint lastPoint;

@property (nonatomic, assign)TouchType touchType;
@property (nonatomic, assign)int movedIndex;

@property (nonatomic, assign)TouchDirection touchDirection;//点的哪个角
@end

#pragma mark -

@implementation DrawingView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}
- (void)configure
{
    self.movedIndex = -1;
    
    self.bufferArray = [NSMutableArray array];
    
    // set the transparent background
    self.backgroundColor = [UIColor clearColor];
}


#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [self.image drawInRect:self.bounds];
    if (self.movedIndex == -1) {
        [self.currentTool draw];
    }
    if (self.touchType == SELECT_MARK || self.touchType == RESIZE_MARK) {
        DrawingTool *rectT = self.bufferArray[self.movedIndex];
        [rectT drawCircle];
    }
}

- (void)updateCacheImage:(BOOL)redraw
{
    // init a context
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    
    if (redraw) {
        // erase the previous image
        self.image = nil;
        
        // I need to redraw all the lines
        for (DrawingTool *tool in self.bufferArray) {
            [tool draw];
        }
        if (self.touchType == SELECT_MARK || self.touchType == UNSELECT_MARK || self.touchType == RESIZE_MARK) {
            DrawingTool *rectT = self.bufferArray[self.movedIndex];
            [rectT drawCircle];
        }
        
    } else {
        // set the draw point
        [self.image drawAtPoint:CGPointZero];
        [self.currentTool draw];
    }
    
    // store the image
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // add the first touch
    UITouch *touch = [touches anyObject];
    self.firstPoint = [touch locationInView:self];
    
    for (int index = 0; index < self.bufferArray.count; index ++) {
        DrawingTool *rectTool = self.bufferArray[index];
        if ((((fabs(self.firstPoint.x - rectTool.firstPoint.x) <= MarkClickSize) || (fabs(self.firstPoint.x - rectTool.lastPoint.x) <= MarkClickSize)) && ((rectTool.firstPoint.y <= self.firstPoint.y) && (self.firstPoint.y <= rectTool.lastPoint.y))) || (((fabs(self.firstPoint.y - rectTool.firstPoint.y) <= MarkClickSize) || (fabs(self.firstPoint.y - rectTool.lastPoint.y) <= MarkClickSize)) && ((rectTool.firstPoint.x <= self.firstPoint.x) && (self.firstPoint.x <= rectTool.lastPoint.x)))) {
            //屏幕上没有选中的矩形
            if (self.movedIndex == -1) {
                self.movedIndex = index;
                rectTool.lineColor = kSelectedLineColor;
                [self.bufferArray replaceObjectAtIndex:index withObject:rectTool];
                [self setNeedsDisplay];
                [self updateCacheImage:YES];
                self.touchType = SELECT_MARK;
            } else {
                if (self.movedIndex == index) {
                    if ([self isInCircle]) {
                        NSLog(@"%s",__FUNCTION__);
                        self.touchType = RESIZE_MARK;
                    } else {
                        self.touchType = UNSELECT_MARK;
                    }
                } else {
                    DrawingTool *rectT = self.bufferArray[self.movedIndex];
                    rectT.lineColor = kDefaultLineColor;
                    [self.bufferArray replaceObjectAtIndex:self.movedIndex withObject:rectT];
                    rectTool.lineColor = kSelectedLineColor;
                    [self.bufferArray replaceObjectAtIndex:index withObject:rectTool];
                    self.movedIndex = index;
                    [self setNeedsDisplay];
                    [self updateCacheImage:YES];
                    self.touchType = SELECT_MARK;
                }
            }
            return;
        }
    }
    //如果有选中的矩形, 取消选中状态. 新建批注
    if (self.movedIndex != -1) {
        DrawingTool *rectT = self.bufferArray[self.movedIndex];
        rectT.lineColor = kDefaultLineColor;
        [self.bufferArray replaceObjectAtIndex:self.movedIndex withObject:rectT];
        self.touchType = NEW_MARK;
        [self setNeedsDisplay];
        [self updateCacheImage:YES];
    }
    self.currentTool = [DrawingTool new];
    self.currentTool.lineWidth = kDefaultLineWidth;
    self.currentTool.lineColor = kDefaultLineColor;
    self.currentTool.lineAlpha = kDefaultLineAlpha;
    self.currentTool.radius = MARK_CIRCLE_SIZE;
    [self.currentTool setInitialPoint:self.firstPoint];
    self.touchType = NEW_MARK;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // save all the touches in the path
    UITouch *touch = [touches anyObject];
    // add the current point to the path
    CGPoint currentLocation = [touch locationInView:self];
    CGPoint previousLocation = [touch previousLocationInView:self];
    switch (self.touchType) {
        case SELECT_MARK:
        case UNSELECT_MARK: {
            DrawingTool *newRectTool = self.bufferArray[self.movedIndex];
            CGPoint newRectFirstPoint = CGPointMake(newRectTool.firstPoint.x + (currentLocation.x - previousLocation.x), newRectTool.firstPoint.y + (currentLocation.y - previousLocation.y));
            CGPoint newRectLastPoint = CGPointMake(newRectTool.lastPoint.x + (currentLocation.x - previousLocation.x), newRectTool.lastPoint.y + (currentLocation.y - previousLocation.y));
            [newRectTool moveFromPoint:newRectFirstPoint toPoint:newRectLastPoint];
            
            [self setNeedsDisplay];
            [self updateCacheImage:YES];
            break;
        }
        case NEW_MARK: {
            self.movedIndex = -1;
            [self.currentTool moveFromPoint:self.firstPoint toPoint:currentLocation];
            [self setNeedsDisplay];
            [self updateCacheImage:YES];
            break;
        }
        case RESIZE_MARK: {
            DrawingTool *newRectTool = self.bufferArray[self.movedIndex];
            switch (self.touchDirection) {
                case Left_Top: {
                    CGPoint newRectFirstPoint = CGPointMake(newRectTool.firstPoint.x + (currentLocation.x - previousLocation.x), newRectTool.firstPoint.y + (currentLocation.y - previousLocation.y));
                    [newRectTool moveFromPoint:newRectFirstPoint toPoint:newRectTool.lastPoint];
                    [self setNeedsDisplay];
                    [self updateCacheImage:YES];
                    break;
                }
                case Left_Bottom: {
                    CGPoint newRectFirstPoint = CGPointMake(newRectTool.firstPoint.x + (currentLocation.x - previousLocation.x), newRectTool.lastPoint.y + (currentLocation.y - previousLocation.y));
                    CGPoint newRectLastPoint = CGPointMake(newRectTool.lastPoint.x, newRectTool.firstPoint.y);
                    [newRectTool moveFromPoint:newRectFirstPoint toPoint:newRectLastPoint];
                    [self setNeedsDisplay];
                    [self updateCacheImage:YES];
                    break;
                }
                case Right_Top: {
                    CGPoint newRectFirstPoint = CGPointMake(newRectTool.lastPoint.x + (currentLocation.x - previousLocation.x), newRectTool.firstPoint.y + (currentLocation.y - previousLocation.y));
                    CGPoint newRectLastPoint = CGPointMake(newRectTool.firstPoint.x, newRectTool.lastPoint.y);
                    [newRectTool moveFromPoint:newRectFirstPoint toPoint:newRectLastPoint];
                    [self setNeedsDisplay];
                    [self updateCacheImage:YES];
                    break;
                }
                case Right_Bottom: {
                    CGPoint newRectLastPoint = CGPointMake(newRectTool.lastPoint.x + (currentLocation.x - previousLocation.x), newRectTool.lastPoint.y + (currentLocation.y - previousLocation.y));
                    [newRectTool moveFromPoint:newRectTool.firstPoint toPoint:newRectLastPoint];
                    [self setNeedsDisplay];
                    [self updateCacheImage:YES];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //
    UITouch *touch = [touches anyObject];
    self.lastPoint  = [touch locationInView:self];
    if (self.touchType == NEW_MARK && !CGPointEqualToPoint(self.firstPoint, self.lastPoint)) {
        [self.bufferArray addObject:self.currentTool];
        // make sure a point is recorded
        [self touchesMoved:touches withEvent:event];
    }
    if (self.touchType == NEW_MARK && CGPointEqualToPoint(self.firstPoint, self.lastPoint)) {
        self.movedIndex = -1;
    }
//    if (self.touchType == RESIZE_MARK) {
//        [self resumeCoordinate];
//    }
    // update the image
//    [self updateCacheImage:NO];
    
    // clear the current tool
    self.currentTool = nil;
    
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // make sure a point is recorded
    [self touchesEnded:touches withEvent:event];
}
/**
 * 是否选中批注矩形框的四个圆角
 */
- (BOOL)isInCircle {
    DrawingTool *rectT = self.bufferArray[self.movedIndex];
    if ([self inCircleWithX:rectT.firstPoint.x y:rectT.firstPoint.y]) {
        self.touchDirection = Left_Top;
        return YES;
    }
    if ([self inCircleWithX:rectT.firstPoint.x y:rectT.lastPoint.y]) {
        self.touchDirection = Left_Bottom;
        return YES;
    }
    if ([self inCircleWithX:rectT.lastPoint.x y:rectT.firstPoint.y]) {
        self.touchDirection = Right_Top;
        return YES;
    }
    if ([self inCircleWithX:rectT.lastPoint.x y:rectT.lastPoint.y]) {
        self.touchDirection = Right_Bottom;
        return YES;
    }
    return  NO;
}
- (BOOL)inCircleWithX:(double)x y:(double)y {
    return pow(self.firstPoint.x - x, 2) + pow(self.firstPoint.y - y, 2) <= pow(MARK_CIRCLE_SIZE, 2);
}
//重置坐标
//- (void)resumeCoordinate {
//    DrawingTool *newRectTool = self.bufferArray[self.movedIndex];
//    CGPoint newRectFirstPoint = CGPointMake(newRectTool.firstPoint.x < newRectTool.lastPoint.x ? newRectTool.firstPoint.x : newRectTool.lastPoint.x, newRectTool.firstPoint.y < newRectTool.lastPoint.y ? newRectTool.firstPoint.y : newRectTool.lastPoint.y);
//    CGPoint newRectLastPoint = CGPointMake(newRectTool.firstPoint.x > newRectTool.lastPoint.x ? newRectTool.firstPoint.x : newRectTool.lastPoint.x, newRectTool.firstPoint.y > newRectTool.lastPoint.y ? newRectTool.firstPoint.y : newRectTool.lastPoint.y);
//    [newRectTool moveFromPoint:newRectFirstPoint toPoint:newRectLastPoint];
//}
@end
