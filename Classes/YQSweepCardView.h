//
//  YQSweepCardView.h
//  YQSweepCardView
//
//  Created by 王叶庆 on 15/10/14.
//  Copyright © 2015年 王叶庆. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YQSweepCardItem.h"
@class YQSweepCardView;

NS_ASSUME_NONNULL_BEGIN

@protocol YQSweepCardViewDataSource <NSObject>

@required
- (YQSweepCardItem *)sweepCardView:(YQSweepCardView *)sweepCardView itemForIndex:(NSInteger)index;

@end

@interface YQSweepCardView : UIView

@property (nonatomic, weak) id<YQSweepCardViewDataSource> dataSource;

#pragma mark optional
@property (nonatomic, assign) UIEdgeInsets contentInsets;
@property (nonatomic, assign) NSInteger stackCount;
@property (nonatomic, assign) CGFloat backItemScale;
/**
 *  为了让后边的item在视图上显示出边框，调节此值可能需要配合调节contentInsets的值
 */
@property (nonatomic, assign) CGFloat backItemOffset;
#pragma mark required
@property (nonatomic, assign) NSInteger itemCount;
- (void)registerNib:(nullable UINib *)nib forItemReuseIdentifier:(NSString *)identifier;
- (void)registerClass:(nullable Class)itemClass forItemReuseIdentifier:(NSString *)identifier;
- (__kindof YQSweepCardItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END