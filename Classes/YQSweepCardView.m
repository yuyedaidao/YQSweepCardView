//
//  YQSweepCardView.m
//  YQSweepCardView
//
//  Created by 王叶庆 on 15/10/14.
//  Copyright © 2015年 王叶庆. All rights reserved.
//

#import "YQSweepCardView.h"
#import <objc/runtime.h>
@interface YQSweepCardItem (Scale)
//@property (nonatomic) CGFloat itemScale;
@property (nonatomic, strong) NSString *identifier;
@end

@implementation YQSweepCardItem (Scale)
//@dynamic itemScale;
//- (CGFloat)itemScale{
//    return [objc_getAssociatedObject(self, _cmd) floatValue];
//}
//- (void)setItemScale:(CGFloat)itemScale{
//    objc_setAssociatedObject(self, @selector(itemScale), @(itemScale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
@dynamic identifier;

- (NSString *)identifier{
    return (NSString *)objc_getAssociatedObject(self, _cmd);
}
- (void)setIdentifier:(NSString *)identifier{
    objc_setAssociatedObject(self, @selector(identifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

/**
 *  堆叠的数量
 */
static NSInteger const StackCount = 3;
static CGFloat const LimitedRotate = M_PI_2;
@interface YQSweepCardView ()

@property (nonatomic, strong) NSMutableDictionary *registerInfo;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray *> *reusableDic;
@property (nonatomic, strong) NSMutableArray<YQSweepCardItem *> *livingItems;
@property (nonatomic, assign) CGSize topItemSize;
@property (nonatomic, assign) NSInteger currentIndex;


/**
 *  正常情况下偏头度数
 */
@property (nonatomic, assign) CGFloat rotate;
/**
 *  正常情况下动画持续时间
 */
@property (nonatomic, assign) CGFloat animationDuration;



@end

@implementation YQSweepCardView

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self commonInit];
    }
    return self;
}
- (instancetype)init{
    if(self = [super init]){
        [self commonInit];
    }
    return self;
}
- (void)awakeFromNib{
    [self commonInit];
}

#pragma mark self help

- (void)commonInit{
    _rotate = -M_PI_4;
    _backItemOffset = 5.0f;
    _contentInsets = UIEdgeInsetsMake(30, 10, 10, 10);
    _stackCount = StackCount;
    _animationDuration = 1.0;
    
//    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    left.direction = UISwipeGestureRecognizerDirectionLeft;
//    [self addGestureRecognizer:left];
//    UISwipeGestureRecognizer *down = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    down.direction = UISwipeGestureRecognizerDirectionDown;
//    [self addGestureRecognizer:down];
//    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    right.direction = UISwipeGestureRecognizerDirectionRight;
//    [self addGestureRecognizer:right];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:pan];
    
    self.userInteractionEnabled = YES;
}

- (void)panAction:(UIPanGestureRecognizer *)sender{
    CGFloat translation = [sender translationInView:self].x;
    //左滑，随手势向左下角歪到，结束时根据临界值决定复位或者移除视图
    if(sender.state == UIGestureRecognizerStateBegan){
        self.livingItems.lastObject.layer.anchorPoint = CGPointMake(1, 1);
        self.livingItems.lastObject.layer.position = CGPointMake(self.topItemSize.width+self.contentInsets.left, self.topItemSize.height+self.contentInsets.top);
    }else if(sender.state == UIGestureRecognizerStateChanged){
        
        if(translation < 0){
            //让卡片左歪脖
            self.livingItems.lastObject.transform = CGAffineTransformMakeRotation(LimitedRotate*(translation/CGRectGetWidth(self.bounds)));
        }
    }else if(sender.state == UIGestureRecognizerStateEnded){
        //停在起始左边就滑走，停在起始右边就滑入新卡片
        if(translation < 0){
            //飞出去
            YQSweepCardItem *topItem = self.livingItems.lastObject;
            [self.livingItems removeLastObject];
    
            [UIView animateWithDuration:_animationDuration delay:0 usingSpringWithDamping:10 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                topItem.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0), CGAffineTransformMakeTranslation(-self.topItemSize.width-self.contentInsets.left, 0));
            } completion:^(BOOL finished) {
                [topItem removeFromSuperview];
                //添加新item在最下边
                if(self.currentIndex+self.stackCount<self.itemCount){
                    if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
                        YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:self.currentIndex+self.stackCount];
                        item.layer.anchorPoint = CGPointMake(1, 1);
                        item.layer.position = CGPointMake(self.topItemSize.width+self.contentInsets.left, self.topItemSize.height+self.contentInsets.top);
                        [self.livingItems insertObject:item atIndex:0];
                        [self addSubview:item];
                        [self sendSubviewToBack:item];
                        self.currentIndex += 1;
                        //先放到左边看不见的地方，同时旋转一下 弄成个歪脖子效果
    //                    item.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(_rotate), CGAffineTransformMakeTranslation(-self.topItemSize.width/2-a-b, 0));
                    }
                }
            }];
        }else{
            if(self.currentIndex>0){
                if(sender.state == UIGestureRecognizerStateEnded){
                    CGFloat a = self.topItemSize.height/2*sin(_rotate);
                    CGFloat b = self.topItemSize.width/2*cos(_rotate);
                    if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
                        YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:self.currentIndex-1];
                        //先放到左边看不见的地方，同时旋转一下 弄成个歪脖子效果
                        item.layer.anchorPoint = CGPointMake(0.5, 0.5);
                        item.layer.position = CGPointMake(self.topItemSize.width/2+self.contentInsets.left, self.topItemSize.height/2+self.contentInsets.top);
                        [self.livingItems addObject:item];
                        [self addSubview:item];
                        [UIView animateWithDuration:1.3 delay:0 usingSpringWithDamping:10 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            item.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(_rotate), CGAffineTransformMakeTranslation(-self.topItemSize.width-a-b, 0));
                        } completion:^(BOOL finished) {
                            item.layer.anchorPoint = CGPointMake(1, 1);
                            item.layer.position = CGPointMake(self.topItemSize.width+self.contentInsets.left, self.topItemSize.height+self.contentInsets.top);
                            [self.livingItems removeObjectAtIndex:0];
                        }];
                        
                    }
                }
            }
        }

    }
}


#pragma mark public
- (__kindof YQSweepCardItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier{
    id obj = self.registerInfo[identifier];
    NSAssert1(obj, @"您没有注册identifier为%@的item", identifier);
    NSMutableArray *array = self.reusableDic[identifier];
    if(!array){
        array = [NSMutableArray array];
        self.reusableDic[identifier] = array;
    }
    if(array.count){
        YQSweepCardItem *item = array.lastObject;
        [array removeLastObject];
        return item;
    }else{
        if([obj isKindOfClass:[UINib class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[(UINib *)obj instantiateWithOwner:nil options:nil];
            return item;
        }else if([(Class)obj isSubclassOfClass:[YQSweepCardItem class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[[(Class)obj alloc] init];
            return item;
        }else{
            NSAssert1(NO, @"您注册identifier为%@的视图并非是YQSweepCardItem或其子类", identifier);
        }
    }
    return nil;
}

- (void)registerClass:(Class)itemClass forItemReuseIdentifier:(NSString *)identifier{
    self.registerInfo[identifier] = itemClass;
}
- (void)registerNib:(UINib *)nib forItemReuseIdentifier:(NSString *)identifier{
    self.registerInfo[identifier] = nib;
}

- (void)reloadData{
    
    [self.livingItems enumerateObjectsUsingBlock:^(YQSweepCardItem  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        NSMutableArray *array = self.reusableDic[obj.identifier];
        if(array){
            [array addObject:obj];
        }
    }];
    [self.livingItems removeAllObjects];
    if(self.itemCount){
        if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
            for (int i = 0; i<self.stackCount; i++) {
                if(i >= self.itemCount) break;
                YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:i];
                [self.livingItems addObject:item];
                [self addSubview:item];
                //constraints
                item.translatesAutoresizingMaskIntoConstraints = NO;
                [self addConstraint:[NSLayoutConstraint constraintWithItem:item attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:self.contentInsets.left]];
                [self addConstraint:[NSLayoutConstraint constraintWithItem:item attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:-self.contentInsets.right]];
                [self addConstraint:[NSLayoutConstraint constraintWithItem:item attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:self.contentInsets.top]];
                [self addConstraint:[NSLayoutConstraint constraintWithItem:item attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-self.contentInsets.bottom]];
            }
        }
       
        if(self.topItemSize.width<=0)return;
        [self.livingItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(YQSweepCardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            obj.layer.cornerRadius = self.backItemOffset*2;
            if(idx == self.livingItems.count-1){
                obj.transform = CGAffineTransformIdentity;
            }else{
                NSInteger topIndex = self.livingItems.count-idx-1;
                CGFloat scale = 1-self.backItemOffset*2*topIndex/self.topItemSize.width;
                //上移露出边框
                CGFloat moveDistance = self.topItemSize.height*(1-scale)/2;
                obj.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, -moveDistance-topIndex*self.backItemOffset));
            }
        }];
    }
    self.currentIndex = 0;
    
}

#pragma mark override

- (void)layoutSubviews{
    [super layoutSubviews];
    self.topItemSize = CGSizeMake(CGRectGetWidth(self.bounds)-self.contentInsets.left-self.contentInsets.right, CGRectGetHeight(self.bounds)-self.contentInsets.top-self.contentInsets.bottom);
    [self reloadData];
}

- (void)setDataSource:(id<YQSweepCardViewDataSource>)dataSource{
    _dataSource = dataSource;
    if(dataSource){
        [self reloadData];
    }
}

- (NSMutableArray *)livingItems{
    if(!_livingItems){
        _livingItems = [NSMutableArray array];
    }
    return _livingItems;
}
- (NSMutableDictionary *)registerInfo{
    if(!_registerInfo){
        _registerInfo = [NSMutableDictionary dictionary];
    }
    return _registerInfo;
}
- (NSMutableDictionary<NSString *,NSMutableArray *> *)reusableDic{
    if(!_reusableDic){
        _reusableDic = [NSMutableDictionary dictionary];
    }
    return _reusableDic;
}
@end
