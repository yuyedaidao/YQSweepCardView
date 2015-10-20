# YQSweepCardView
仿淘宝‘猜你喜欢’展示卡片

##使用

视图可以通过xib拖的方式
然后

    [self.cardView registerNib:[UINib nibWithNibName:@"MyCard" bundle:nil] forItemReuseIdentifier:@"B"];
    self.cardView.dataSource = self;
    self.cardView.itemCount = 5;
    [self.cardView reloadData];
    
最后
实现代理方法

    - (YQSweepCardItem *)sweepCardView:(YQSweepCardView *)sweepCardView itemForIndex:(NSInteger)index{
        YQSweepCardItem *item =  [sweepCardView dequeueReusableItemWithIdentifier:@"B"];
        // do something
        return item;
    }
