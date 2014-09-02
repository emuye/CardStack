//
//  ViewController.m
//  CardStack
//
//  Created by Emuye Reynolds on 8/29/14.
//  Copyright (c) 2014 EmuyeReynolds. All rights reserved.
//

#import "ViewController.h"
#import "CardStack.h"

static int CARD_COUNT = 10;

@interface ViewController () <CardStackDataSource>
@property (nonatomic, readwrite) NSMutableArray *cards;
@property (nonatomic, readwrite) CardStack *cardStack;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];

    self.cards = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < CARD_COUNT; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT)];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 10;
        [self.cards addObject:card];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, CARD_WIDTH - 40, CARD_HEIGHT - 40)];
        label.backgroundColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:24];
        label.text = [NSString stringWithFormat:@"%d", i + 1];
        label.textColor = [UIColor blackColor];
        label.layer.cornerRadius = 10;
        label.textAlignment = NSTextAlignmentCenter;
        [card addSubview:label];
    }
    
    self.cardStack = [[CardStack alloc] initWithFrame:self.view.bounds];
    self.cardStack.datasource = self;
    [self.view addSubview:self.cardStack];
}

- (int)numberOfItemsInCardStack:(CardStack*)cardStack
{
    return self.cards.count;
}

- (UIView*)cardStack:(CardStack*)cardStack itemAtIndex:(int)index
{
    return [self.cards objectAtIndex:index];
}

- (void)next
{
    [self.cardStack next];
    
    [self performSelector:@selector(next) withObject:nil afterDelay:4];
}

@end
