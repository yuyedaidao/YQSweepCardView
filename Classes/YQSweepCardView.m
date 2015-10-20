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

@property (nonatomic, assign) CGPoint originalAnchorPoint;
@property (nonatomic, assign) CGPoint originalPosition;
@property (nonatomic, assign) CGPoint rotateAnchorPoint;
@property (nonatomic, assign) CGPoint rotatePosition;

@property (nonatomic, weak) YQSweepCardItem *topItem;

@property (nonatomic, assign) BOOL shouldReload;

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
    self.clipsToBounds = YES;
    _rotate = -M_PI_4;
    _backItemOffset = 5.0f;
    _contentInsets = UIEdgeInsetsMake(30, 10, 10, 10);
    _stackCount = StackCount;
    _animationDuration = 0.3;
    _originalAnchorPoint = CGPointMake(0.5, 0.5);
    _rotateAnchorPoint = CGPointMake(1, 1);

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:pan];
    
    self.userInteractionEnabled = YES;
}
- (void)layoutItem:(YQSweepCardItem *)newItem{
    newItem.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:newItem attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:self.contentInsets.left]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:newItem attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:-self.contentInsets.right]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:newItem attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:self.contentInsets.top]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:newItem attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-self.contentInsets.bottom]];
}
- (void)moveOut:(YQSweepCardItem *)movingItem completion:(void(^)(void))completion{
    movingItem.layer.anchorPoint = self.originalAnchorPoint;
    movingItem.layer.position = self.originalPosition;
    [UIView animateWithDuration:_animationDuration delay:0 usingSpringWithDamping:10 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        movingItem.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0), CGAffineTransformMakeTranslation(-self.topItemSize.width-self.contentInsets.left, 0));
        [self.livingItems enumerateObjectsUsingBlock:^(YQSweepCardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
        
    } completion:^(BOOL finished) {
        //回收
        if(completion){
            completion();
        }
    }];
}
- (void)panAction:(UIPanGestureRecognizer *)sender{
    CGFloat translation = [sender translationInView:self].x;
    //左滑，随手势向左下角歪到，结束时根据临界值决定复位或者移除视图
    if(sender.state == UIGestureRecognizerStateBegan){
        self.topItem.layer.anchorPoint = self.rotateAnchorPoint;
        self.topItem.layer.position = self.rotatePosition;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        if(translation < 0){
            //让卡片左歪脖
            self.topItem.transform = CGAffineTransformMakeRotation(LimitedRotate*(translation/CGRectGetWidth(self.bounds)));
        }
    }else if(sender.state == UIGestureRecognizerStateEnded){
        //停在起始左边就滑走，停在起始右边就滑入新卡片
        if(translation < 0){
            //飞出去
            NSInteger index = MIN(self.currentIndex+self.stackCount,self.itemCount);
            YQSweepCardItem *newItem = nil;
            YQSweepCardItem *movingItem = nil;
            if(index < self.itemCount){
                if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
                    newItem = [self.dataSource sweepCardView:self itemForIndex:index];
                    if(!newItem.superview){
                        [self addSubview:newItem];
                        [self layoutItem:newItem];
                    }
                    [self sendSubviewToBack:newItem];
                    self.currentIndex += 1;
                    [self.livingItems removeLastObject];
                    movingItem = self.topItem;
                    self.topItem = self.livingItems.lastObject;
                    [self.livingItems insertObject:newItem atIndex:0];
                }
                __weak typeof(self) weakSelf = self;
                [self moveOut:movingItem completion:^{
                    [weakSelf.reusableDic[movingItem.identifier] addObject:movingItem];
                }];
                

            }else{//这种情况，把statcount-1个item移走
                if(self.currentIndex<self.itemCount-1){
                    __weak typeof(self) weakSelf = self;
                    [weakSelf.livingItems removeLastObject];
                    [self moveOut:self.topItem completion:^{
                        [weakSelf.reusableDic[weakSelf.topItem.identifier] addObject:weakSelf.topItem];
                        weakSelf.currentIndex += 1;
                        weakSelf.topItem = weakSelf.livingItems.lastObject;
                    }];
                    
                }else{
                    [UIView animateWithDuration:_animationDuration delay:0 usingSpringWithDamping:10 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        self.topItem.transform = CGAffineTransformIdentity;
                    } completion:nil];
                }
                
            }

        }else{
            if(self.currentIndex>0){
                if(sender.state == UIGestureRecognizerStateEnded){
                    NSLog(@"进来===== %ld",self.currentIndex);
                    if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
                        YQSweepCardItem *newItem = [self.dataSource sweepCardView:self itemForIndex:self.currentIndex-1];
                        YQSweepCardItem *oldItem = nil;
                        if(self.livingItems.count >= self.stackCount){
                            oldItem = self.livingItems.firstObject;
                            [self.livingItems removeObjectAtIndex:0];
                        }
                        //因为手势开始给第二个视图layer的锚点做了改变，这里应该改回来
                        self.topItem.layer.anchorPoint = self.originalAnchorPoint;
                        self.topItem.layer.position = self.originalPosition;
                        
                        [self.livingItems addObject:newItem];

                        if(!newItem.superview){
                            [self addSubview:newItem];
                            [self layoutItem:newItem];
                        }
                        [self bringSubviewToFront:newItem];
                        
                        newItem.layer.anchorPoint = self.originalAnchorPoint;
                        newItem.layer.position = self.originalPosition;
                        CGAffineTransform transform = CGAffineTransformMakeTranslation(-CGRectGetWidth(self.frame)-self.contentInsets.left, 0);
                        newItem.transform = transform;
                        if(oldItem){
                            oldItem.layer.anchorPoint = self.originalAnchorPoint;
                            oldItem.layer.position = self.originalPosition;
                        }
                        
                        [UIView animateWithDuration:_animationDuration delay:0 usingSpringWithDamping:10 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            if(oldItem){
                                oldItem.transform = transform;
                            }
                    
                            [self.livingItems enumerateObjectsUsingBlock:^(YQSweepCardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

                        } completion:^(BOOL finished) {
                            
                            self.topItem = newItem;
                            self.currentIndex -= 1;
                            oldItem.hidden = YES;
                            [self.reusableDic[oldItem.identifier] addObject:oldItem];
                        }];
                        
                    }
                }
            }else{//currentIndex == 0
                
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
        item.hidden = NO;
        [array removeLastObject];
        return item;
    }else{
        if([obj isKindOfClass:[UINib class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[(UINib *)obj instantiateWithOwner:nil options:nil].lastObject;
            item.identifier = identifier;
            return item;
        }else if([(Class)obj isSubclassOfClass:[YQSweepCardItem class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[[(Class)obj alloc] init];
            item.identifier = identifier;
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
            NSInteger count = MIN(self.stackCount, self.itemCount);
            for (NSInteger i = count-1; i>=0; i--) {
                YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:i];
                [self.livingItems addObject:item];
                [self addSubview:item];
                //constraints
                [self layoutItem:item];
            }
        }
        [self layoutIfNeeded];
        if(self.topItemSize.width<=0)return;
        [self.livingItems enumerateObjectsUsingBlock:^(YQSweepCardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
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
    self.topItem = self.livingItems.lastObject;
    self.currentIndex = 0;
    
    
}

#pragma mark override

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.topItemSize = CGSizeMake(CGRectGetWidth(self.bounds)-self.contentInsets.left-self.contentInsets.right, CGRectGetHeight(self.bounds)-self.contentInsets.top-self.contentInsets.bottom);
    _originalPosition = CGPointMake(_topItemSize.width/2+self.contentInsets.left, _topItemSize.height/2+self.contentInsets.top);
    _rotatePosition = CGPointMake(_topItemSize.width+self.contentInsets.left, _topItemSize.height+self.contentInsets.top);
    
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
