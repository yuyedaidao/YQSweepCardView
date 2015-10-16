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
@property (nonatomic) CGFloat itemScale;
@end

@implementation YQSweepCardItem (Scale)
@dynamic itemScale;
- (CGFloat)itemScale{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}
- (void)setItemScale:(CGFloat)itemScale{
    objc_setAssociatedObject(self, @selector(itemScale), @(itemScale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

/**
 *  堆叠的数量
 */
static NSInteger const StackCount = 3;

@interface YQSweepCardView ()

@property (nonatomic, strong) NSMutableDictionary *registerInfo;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray *> *reusableDic;
@property (nonatomic, strong) NSMutableArray<YQSweepCardItem *> *livingItems;

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
    _contentInsets = UIEdgeInsetsMake(30, 10, 10, 10);
    _stackCount = StackCount;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:pan];
//    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    left.direction = UISwipeGestureRecognizerDirectionLeft;
//    [self addGestureRecognizer:left];
//    UISwipeGestureRecognizer *down = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    down.direction = UISwipeGestureRecognizerDirectionDown;
//    [self addGestureRecognizer:down];
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    right.direction = UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:right];

    self.userInteractionEnabled = YES;
}

- (void)panAction:(id)sender{
    //左滑，随手势向左下角歪到，结束时根据临界值决定复位或者移除视图
}
- (void)swipeAction:(UISwipeGestureRecognizer *)sender{
    //向右扫，进来视图
    
}

- (void)configureTransformForItem:(YQSweepCardItem *)item atIndex:(NSInteger)index{
    //
    item.frame = CGRectMake(self.contentInsets.left, self.contentInsets.top, CGRectGetWidth(self.frame)-self.contentInsets.left-self.contentInsets.right, CGRectGetHeight(self.frame)-self.contentInsets.top-self.contentInsets.bottom);
    CGFloat scale = 1-index*self.backItemScale;
    item.transform = CGAffineTransformMakeScale(scale, scale);
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
        return array.lastObject;
    }else{
        if([obj isKindOfClass:[UINib class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[(UINib *)obj instantiateWithOwner:nil options:nil];
            [array addObject:item];
            return item;
        }else if([(Class)obj isSubclassOfClass:[YQSweepCardItem class]]){
            YQSweepCardItem *item = (YQSweepCardItem *)[[(Class)obj alloc] init];
            [array addObject:item];
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
    
    //先删除之前的item,然后添加当前的item
    [self.livingItems enumerateObjectsUsingBlock:^(YQSweepCardItem  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.livingItems removeAllObjects];
    if(self.itemCount){
        if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
            for (int i = 0; i<self.stackCount; i++) {
                if(i >= self.itemCount) break;
                YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:i];
                item.itemScale = 1;
                [self.livingItems addObject:item];
                item.frame = CGRectMake(self.contentInsets.left, self.contentInsets.top, CGRectGetWidth(self.frame)-self.contentInsets.left-self.contentInsets.right, CGRectGetHeight(self.frame)-self.contentInsets.top-self.contentInsets.bottom);
                [self addSubview:item];
            }
        }
        
        [self.livingItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(YQSweepCardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx>0){
                YQSweepCardItem *oldItem = self.livingItems[idx-1];
                CGFloat scale = oldItem.itemScale*self.backItemScale;//缩放是前一张的scale倍
                obj.itemScale = scale;
                //上移露出边框
                CGFloat realOffset = self.backItemOffset/scale;
                obj.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, -realOffset));
                
            }
            
        }];

    }
    
}

#pragma mark override
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
