//
//  TransparentNavigationBar.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/6/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "TransparentNavigationBar.h"

@implementation TransparentNavigationBar

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0] set];
    UIRectFill(rect);
}


@end
