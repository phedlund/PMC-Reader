//
//  PHCollectionViewCell.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/11/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PHCollectionViewCell.h"

@implementation PHCollectionViewCell

@synthesize delegate = _delegate;
@synthesize openGestureRecognizer;
@synthesize closeGestureRecognizer;
@synthesize buttonsVisible;
@synthesize activityVisible;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {        
        //
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.buttonsVisible = NO;

        [self addGestureRecognizer:self.openGestureRecognizer];
        [self addGestureRecognizer:self.closeGestureRecognizer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.activityBackground.layer.cornerRadius = 8.0f;
    self.activityBackground.clipsToBounds = YES;
    
    if (self.buttonsVisible) {
        [self hideButtons];
    } else {
        self.contentView.frame = self.bounds;
        self.activityBackground.frame = CGRectMake((self.contentView.frame.size.width - self.activityBackground.frame.size.width) / 2, (self.contentView.frame.size.height - self.activityBackground.frame.size.height) / 2, self.activityBackground.frame.size.width, self.activityBackground.frame.size.height);
        self.labelContainerView.frame = self.bounds;
        self.buttonContainerView.frame = CGRectMake(self.contentView.frame.size.width, 0, 0, self.contentView.frame.size.height);
        if (self.contentView.frame.size.width > 400) {
            self.titleLabel.frame = CGRectMake(10, 10, self.labelContainerView.frame.size.width - 20, 45);
            self.authorLabel.frame = CGRectMake(10, 58, self.labelContainerView.frame.size.width - 20, 40);
            self.publishedAsLabel.frame = CGRectMake(10, 101, self.labelContainerView.frame.size.width - 20, 21);
            self.originalSourceLabel.frame = CGRectMake(10, 124, self.labelContainerView.frame.size.width - 20, 40);
        } else {
            self.titleLabel.frame = CGRectMake(10, 10, self.labelContainerView.frame.size.width - 20, 95);
            self.authorLabel.frame = CGRectMake(10, 120, self.labelContainerView.frame.size.width - 20, 70);
            self.publishedAsLabel.frame = CGRectMake(10, 215, self.labelContainerView.frame.size.width - 20, 21);
            self.originalSourceLabel.frame = CGRectMake(10, 240, self.labelContainerView.frame.size.width - 20, 60);
        }
    }
}

- (void)setActivityVisible:(BOOL)visible {
    if (visible) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    self.activityBackground.hidden = !visible;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if ([gesture isEqual:self.openGestureRecognizer]) {
        if (self.buttonsVisible)
            return;
        
        BOOL canSwipe = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewCellShouldSwipe:)])
            canSwipe = [self.delegate collectionViewCellShouldSwipe:self];
        
        if (!canSwipe)
            return;
        
        [self showButtons];
    }
    
    if ([gesture isEqual:self.closeGestureRecognizer]) {
        if (self.backgroundView.hidden)
            return;
        
        [self hideButtons];
    }
}


- (void)hideButtons
{
    if (!self.buttonsVisible)
        return;
    
    [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction) animations: ^{
        self.labelContainerView.frame = self.bounds;
        self.buttonContainerView.frame = CGRectMake(self.contentView.frame.size.width, 0, 0, self.contentView.frame.size.height);
    } completion:^(BOOL finished) {
        self.buttonsVisible = NO;
    }];
}

- (void)showButtons
{
    if (self.buttonsVisible)
        return;

    [self setSelected:NO];

    CGFloat offsetX = 80.0f;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations: ^{
        self.labelContainerView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.frame.size.width - offsetX, self.contentView.frame.size.height);
        self.buttonContainerView.frame = CGRectMake(self.contentView.frame.size.width - offsetX, self.contentView.frame.origin.y, offsetX, self.contentView.frame.size.height);
    } completion: ^(BOOL finished) {
        [self.delegate collectionViewCellSwiped:self];
        self.buttonsVisible = YES;
    }];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
}

- (UISwipeGestureRecognizer *)openGestureRecognizer {
    if (!openGestureRecognizer) {
        openGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        openGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    
    return openGestureRecognizer;
}

- (UISwipeGestureRecognizer *)closeGestureRecognizer {
    if (!closeGestureRecognizer) {
        closeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        closeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    }
    
    return closeGestureRecognizer;
}

- (IBAction)doDelete:(UIButton *)sender {
    [self.delegate buttonTapped:sender inCell:self];
}

- (IBAction)doDownload:(UIButton *)sender {
    [self.delegate buttonTapped:sender inCell:self];
}
@end
