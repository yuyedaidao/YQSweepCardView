//
//  YQSweepCardView.m
//  YQSweepCardView
//
//  Created by 王叶庆 on 15/10/14.
//  Copyright © 2015年 王叶庆. All rights reserved.
//

#import "YQSweepCardView.h"

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


- (instancetype)init{
    if(self = [super init]){
        [self commonInit];
    }
    return self;
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
        }else if([obj isKindOfClass:[YQSweepCardItem class]]){
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
    if(self.itemCount){
        if([self.dataSource respondsToSelector:@selector(sweepCardView:itemForIndex:)]){
            for (int i = 0; i<self.stackCount; i++) {
                if(i >= self.itemCount) break;
                YQSweepCardItem *item = [self.dataSource sweepCardView:self itemForIndex:i];
                [self.livingItems addObject:item];
                [self addSubview:item];
            }
        }
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
