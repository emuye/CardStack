//
//  CardStack.h
//  CardStack
//
//  Created by Emuye Reynolds on 9/1/14.
//  Copyright (c) 2014 EmuyeReynolds. All rights reserved.
//

static int VISIBLE_CARD_COUNT = 4;
static int CARD_WIDTH = 280;
static int CARD_HEIGHT = 320;

#import <UIKit/UIKit.h>
@protocol CardStackDataSource;

@interface CardStack : UIView
@property (nonatomic, weak, readwrite) id<CardStackDataSource> datasource;
@property (nonatomic, assign, readwrite) int currentTopCardIndex;

- (void)reloadData;
- (void)next;

@end


@protocol CardStackDataSource <NSObject>

- (int)numberOfItemsInCardStack:(CardStack*)cardStack;
- (UIView*)cardStack:(CardStack*)cardStack itemAtIndex:(int)index;
@end
