//
//  ViewController.m
//  YQSweepCardView
//
//  Created by 王叶庆 on 15/10/14.
//  Copyright © 2015年 王叶庆. All rights reserved.
//

#import "ViewController.h"
#import "YQSweepCardView.h"
@interface ViewController ()<YQSweepCardViewDataSource>
@property (weak, nonatomic) IBOutlet YQSweepCardView *cardView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.cardView registerClass:[YQSweepCardItem class] forItemReuseIdentifier:@"A"];
    self.cardView.dataSource = self;
    self.cardView.itemCount = 7;
    [self.cardView reloadData];
}


- (YQSweepCardItem *)sweepCardView:(YQSweepCardView *)sweepCardView itemForIndex:(NSInteger)index{
    NSLog(@"------%d",index);
    YQSweepCardItem *item =  [sweepCardView dequeueReusableItemWithIdentifier:@"A"];
    item.backgroundColor = [UIColor grayColor];
    return item;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
