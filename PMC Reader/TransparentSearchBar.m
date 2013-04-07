//
//  TransparentSearchBar.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/6/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "TransparentSearchBar.h"

@implementation TransparentSearchBar

- (void)didAddSubview:(UIView *)subview {
    if (![subview isKindOfClass:[UITextField class]]) {
        subview.alpha = 0.0f;
    }
}

@end
