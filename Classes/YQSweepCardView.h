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

- (YQSweepCardItem *)sweepCardView:(YQSweepCardView *)sweepCardView itemForIndex:(NSInteger)index;

@end

@interface YQSweepCardView : UIView

@property (nonatomic, weak) id<YQSweepCardViewDataSource> dataSource;

- (void)registerNib:(nullable UINib *)nib forItemReuseIdentifier:(NSString *)identifier;
- (void)registerClass:(nullable Class)itemClass forItemReuseIdentifier:(NSString *)identifier;
- (__kindof YQSweepCardItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END