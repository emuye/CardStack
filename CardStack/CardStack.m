//
//  CardStack.m
//  CardStack
//
//  Created by Emuye Reynolds on 9/1/14.
//  Copyright (c) 2014 EmuyeReynolds. All rights reserved.
//

#import "CardStack.h"

typedef enum
{
    TOP_CARD,
    SECOND_CARD,
    THIRD_CARD,
    FOURTH_CARD,
    OFF_SCREEN,
    BEHIND_STACK
} CardStackState;

static int CARD_CONTENT_TAG = 1;

@interface CardStack (Private)
- (void)_sendToBack:(UIView *)card;
- (void)_addPropertiesToCard:(UIView *)card forState:(CardStackState)cardState animate:(BOOL)animate;
- (void)_panOccurred:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)_completeOffscreenAnimationWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay;
@end

@interface CardStack () <UIGestureRecognizerDelegate>
@property (nonatomic, assign, readwrite) int itemCount;
@property (nonatomic, assign, readwrite) int nextCardIndex;
@property (nonatomic, strong, readwrite) NSMutableArray *cards;
@end

@implementation CardStack

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }

    self.cards = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)setDatasource:(id<CardStackDataSource>)datasource
{
    _datasource = datasource;
    
    [self reloadData];
}

- (void)reloadData
{
    for (int i = 0; i < self.cards.count; i++) {
        [self.cards[i] removeFromSuperview];
    }
    
    self.itemCount = [self.datasource numberOfItemsInCardStack:self];
    if (self.itemCount == 0) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = NO;
    
    int visibleCardCount = MIN(VISIBLE_CARD_COUNT, self.itemCount);
    for (int i = 0; i < visibleCardCount; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT)];
        card.layer.cornerRadius = 10;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panOccurred:)];
        panGestureRecognizer.delegate = self;
        card.gestureRecognizers = @[panGestureRecognizer];
        
        [self addSubview:card];
        [self.cards addObject:card];
        
        [self _addPropertiesToCard:card forState:i animate:NO];
        
        UIView *content = [self.datasource cardStack:self itemAtIndex:i];
        content.tag = CARD_CONTENT_TAG;
        [card addSubview:content];
    }

    if (self.itemCount > 4) {
        // Add one temporary card to use for animations.
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT)];
        card.layer.cornerRadius = 10;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panOccurred:)];
        panGestureRecognizer.delegate = self;
        card.gestureRecognizers = @[panGestureRecognizer];
        
        [self addSubview:card];
        [self.cards addObject:card];
        
        [self _addPropertiesToCard:card forState:BEHIND_STACK animate:NO];
    }

    self.currentTopCardIndex = 0;
    self.nextCardIndex = VISIBLE_CARD_COUNT - 1;
}

- (void)next
{
    if (self.itemCount <= VISIBLE_CARD_COUNT) {
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            [self _addPropertiesToCard:self.cards[0] forState:OFF_SCREEN animate:YES];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
                for (int i = 1; i < self.cards.count; i++) {
                    [self _addPropertiesToCard:self.cards[i] forState:i-1 animate:NO];
                }
                
                [self _addPropertiesToCard:self.cards[0] forState:MIN(self.itemCount - 1, FOURTH_CARD) animate:NO];
            } completion:^(BOOL finished) {
                [self _completeOffscreenAnimationWithDuration:0 delay:0];
            }];
        }];
    } else {
        [UIView animateKeyframesWithDuration:0.5 delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.35 animations:^{
                [self _addPropertiesToCard:self.cards[0] forState:OFF_SCREEN animate:YES];
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.35 relativeDuration:0.65 animations:^{
                CardStackState state = self.itemCount > VISIBLE_CARD_COUNT ? BEHIND_STACK : FOURTH_CARD;
                [self _addPropertiesToCard:self.cards[0] forState:MIN(self.itemCount - 1, state) animate:NO];
            }];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
                for (int i = 1; i < self.cards.count; i++) {
                    [self _addPropertiesToCard:self.cards[i] forState:i-1 animate:NO];
                }
            } completion:^(BOOL finished) {
                [self _completeOffscreenAnimationWithDuration:0 delay:0];
            }];
        }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = NO;
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && self.itemCount > 1) {
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
        if (translation.x <= 0) {
            shouldBegin = YES;
        }
    }
    
    return  shouldBegin;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end

@implementation CardStack (Private)
- (void)_sendToBack:(UIView *)card
{
    card.frame = CGRectMake(-640, 32, CARD_WIDTH, CARD_HEIGHT);
    card.transform = CGAffineTransformIdentity;
    card.alpha = 0.5;
}

- (void)_addPropertiesToCard:(UIView *)card forState:(CardStackState)cardState animate:(BOOL)animate
{
    switch (cardState) {
        case TOP_CARD:
            card.center = self.center;
            card.transform = CGAffineTransformIdentity;
            card.alpha = 1;
            card.layer.zPosition = 4;
            card.userInteractionEnabled = YES;
            card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:10].CGPath;
            card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
            card.layer.shadowRadius = 2;
            card.layer.shadowOffset = CGSizeMake(2, 2);
            card.layer.shadowOpacity = 1;
            break;
        case SECOND_CARD:
            card.center = CGPointMake(self.center.x, self.center.y + 15);
            card.transform = CGAffineTransformMakeScale(0.942857143, 0.942857143);
            card.layer.zPosition = 3;
            card.alpha = 1;
            card.userInteractionEnabled = NO;
            card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:10].CGPath;
            card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.37].CGColor;
            card.layer.shadowRadius = 2;
            card.layer.shadowOffset = CGSizeMake(2, 2);
            card.layer.shadowOpacity = 1;
            break;
        case THIRD_CARD:
            card.center = CGPointMake(self.center.x, self.center.y + 35);
            card.transform = CGAffineTransformMakeScale(0.857142857, 0.857142857);
            card.layer.zPosition = 2;
            card.alpha = 1;
            card.userInteractionEnabled = NO;
            card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:10].CGPath;
            card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.42].CGColor;
            card.layer.shadowRadius = 2;
            card.layer.shadowOffset = CGSizeMake(2, 2);
            card.layer.shadowOpacity = 1;
            break;
        case FOURTH_CARD:
            card.center = CGPointMake(self.center.x, self.center.y + 50);
            card.transform = CGAffineTransformMakeScale(0.8, 0.8);
            card.alpha = 1;
            card.layer.zPosition = 1;
            card.userInteractionEnabled = NO;
            card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:10].CGPath;
            card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
            card.layer.shadowRadius = 2;
            card.layer.shadowOffset = CGSizeMake(2, 2);
            card.layer.shadowOpacity = 1;
            break;
        case OFF_SCREEN:
            card.transform = CGAffineTransformIdentity;
            card.center = CGPointMake(-CARD_WIDTH/2, self.center.y + 50);
            card.alpha = 0.6;
            card.layer.zPosition = 0;
            card.userInteractionEnabled = NO;
            break;
            
        case BEHIND_STACK:
            card.center = CGPointMake(self.center.x, self.center.y + 70);
            card.transform = CGAffineTransformMakeScale(0.5, 0.5);
            card.alpha = 0;
            card.layer.zPosition = 0;
            card.userInteractionEnabled = NO;
            break;
            
        default:
            break;
    }
}

- (void)_panOccurred:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint velocity = [gestureRecognizer velocityInView:self];
    float centerX = self.center.x;
    float centerY = self.center.y;
    
    UIView *card = (UIView*)self.cards[0];

    CGPoint translation = [gestureRecognizer translationInView:self];
    CGPoint newPos = card.center;
    newPos.x += translation.x * 1;
    newPos.y += translation.y * 0.25;
    
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    switch (state)
    {
        case UIGestureRecognizerStateBegan:
        {
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            if ( newPos.x <= centerX && newPos.x >= -CARD_WIDTH && newPos.y <= centerY + 50 && newPos.y >= centerY - 50) // distance threshold
            {
                float delta = centerX - newPos.x;
                delta /= self.bounds.size.width;
                delta = fabs(delta);
                delta = 1 - delta;
//                ((Input - InputLow) / (InputHigh - InputLow)) * (OutputHigh - OutputLow) + OutputLow;
                
                float newAlpha = (delta - 0) / (1 - 0) * (1 - 0.8) + 0.8;
                float newZRot = (delta - 0) / (1 - 0) * (5 + 5) - 5;
                [UIView animateWithDuration:0.1 animations:^{
                    card.center = newPos;
                    card.alpha = newAlpha;
                    card.layer.transform = CATransform3DMakeRotation(-newZRot *  M_PI / 180, 0, 0, 1);
                    card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:10].CGPath;
                }];
            }
            
            [gestureRecognizer setTranslation:CGPointZero inView:self];
            
            break;
        }
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        {
            // Use 1200 velocity threshold when the view is in the center
            // down to 400 velocity threshold when the view is half way over.
            float velocityThreshold = 400 + ( ( newPos.x / centerX ) * 800 );

            // TODO:I can't seem to reset this in an animation block. Doing so causes crazy view transformation stuff (even after the transform has been reset)
            card.layer.transform = CATransform3DIdentity;

            if (newPos.x <= -CARD_WIDTH/4) // distance threshold
            {
                [self next];
            }
            else if (-velocity.x >= velocityThreshold ) { // velocity threshold
                [self next];
            }
            else // Snap back to the beginning position
            {
                [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^ {
                    [self _addPropertiesToCard:self.cards[0] forState:TOP_CARD animate:YES];
                } completion:^(BOOL finished) {
                }];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)_completeOffscreenAnimationWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay
{
    UIView *oldTop = self.cards[0];
    
    for (int i = 0; i < self.cards.count - 1; i++) {
        self.cards[i] = self.cards[i + 1];
    }
    self.cards[self.cards.count - 1] = oldTop;
    
    self.currentTopCardIndex++;
    self.nextCardIndex++;
    
    if (self.itemCount >= VISIBLE_CARD_COUNT) {
        if (self.nextCardIndex >= self.itemCount) {
            self.nextCardIndex = 0;
        }
        
        UIView *nextContent = [self.datasource cardStack:self itemAtIndex:self.nextCardIndex];
        nextContent.tag = CARD_CONTENT_TAG;
        [[self.cards[3] viewWithTag:CARD_CONTENT_TAG] removeFromSuperview];
        [self.cards[3] addSubview:nextContent];
    }
}

@end

