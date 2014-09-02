//
//  ViewController.m
//  CardStack
//
//  Created by Emuye Reynolds on 8/29/14.
//  Copyright (c) 2014 EmuyeReynolds. All rights reserved.
//

#import "ViewController.h"
#import "CardStack.h"

static int CARD_COUNT = 9;
static int BUTTON_TAG = 20;

@interface ViewController () <CardStackDataSource>
@property (nonatomic, readwrite) NSMutableArray *cards;
@property (nonatomic, readwrite) NSMutableIndexSet *addIndexes;
@property (nonatomic, readwrite) CardStack *cardStack;
@end

@interface ViewController (Private)
- (void)_deleteSelected:(UIControl*)sender;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];

    self.cards = [[NSMutableArray alloc] init];
    self.addIndexes = [[NSMutableIndexSet alloc] init];
    
    srandom(time(NULL));

    for (int i = 0; i < CARD_COUNT; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT)];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 10;
        [self.cards addObject:card];
        
        BOOL isAdd = random() % 2 == 0; //i == 1 || i == 2 || i == 3 || i == 4 || i == 7 || i  == 8 || i == 9;
        [self.addIndexes addIndex:i];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, CARD_WIDTH - 40, CARD_HEIGHT - 40)];
        label.backgroundColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:24];
        label.text = isAdd ? [NSString stringWithFormat:@"AD %d", i + 1] : [NSString stringWithFormat:@"%d", i + 1];
        label.textColor = [UIColor blackColor];
        label.layer.cornerRadius = 10;
        label.textAlignment = NSTextAlignmentCenter;
        [card addSubview:label];
        
        if (isAdd) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setTitle:@"DELETE" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [button sizeToFit];
            button.center = CGPointMake(label.center.x, label.center.y + 60);
            [button addTarget:self action:@selector(_deleteSelected:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = BUTTON_TAG;
            [card addSubview:button];
        }
        
//        label = [[UILabel alloc] initWithFrame:CGRectMake(20, CARD_HEIGHT - 10, CARD_WIDTH - 40, 10)];
//        label.backgroundColor = [UIColor whiteColor];
//        label.font = [UIFont systemFontOfSize:10];
//        label.text = [NSString stringWithFormat:@"%d", i + 1];
//        label.textColor = [UIColor blackColor];
//        label.layer.cornerRadius = 10;
//        label.textAlignment = NSTextAlignmentCenter;
//        [card addSubview:label];

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

- (BOOL)cardStack:(CardStack*)cardStack itemAtIndexWillDisappear:(int)index
{
    BOOL removeOnDispapear = NO;
    
    UIView *card = [self.cards objectAtIndex:index];
    if ([card viewWithTag:BUTTON_TAG]) {
        removeOnDispapear = YES;
        [self.cards removeObject:card];
    }
    
    
    return removeOnDispapear;
}


@end

@implementation ViewController (Private)
- (void)_deleteSelected:(UIControl*)sender
{
    UIView *card = nil;
    for (UIView *curCard in self.cards) {
        UIButton *button = (UIButton *)[curCard viewWithTag:BUTTON_TAG];
        if (button == sender) {
            card = curCard;
            break;
        }
    }
    
    if (card != nil) {
        NSUInteger index = [self.cards indexOfObject:card];
        [self.cards removeObjectAtIndex:index];
        [self.cardStack deleteCurrentItem];
    }
}
@end
