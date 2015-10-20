//
//  ViewController.m
//  YQSweepCardView
//
//  Created by 王叶庆 on 15/10/14.
//  Copyright © 2015年 王叶庆. All rights reserved.
//

#import "ViewController.h"
#import "YQSweepCardView.h"
#import "MyCard.h"

@interface ViewController ()<YQSweepCardViewDataSource>
@property (weak, nonatomic) IBOutlet YQSweepCardView *cardView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self.cardView registerClass:[YQSweepCardItem class] forItemReuseIdentifier:@"A"];
    [self.cardView registerNib:[UINib nibWithNibName:@"MyCard" bundle:nil] forItemReuseIdentifier:@"B"];
//    self.cardView.dataSource = self;
    self.cardView.itemCount = 5;
    
    [self.cardView reloadData];
}


- (YQSweepCardItem *)sweepCardView:(YQSweepCardView *)sweepCardView itemForIndex:(NSInteger)index{

    YQSweepCardItem *item =  [sweepCardView dequeueReusableItemWithIdentifier:@"B"];
    item.backgroundColor = [UIColor colorWithRed:arc4random()%255/255.0 green:arc4random()%255/255.0 blue:arc4random()%255/255.0 alpha:1];
    item.layer.cornerRadius = 5.0f;
    item.clipsToBounds = YES;
    return item;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
