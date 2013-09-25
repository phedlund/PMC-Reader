//
//  UIImage+PHColor.m
//  PMC Reader
//
//  Created by Peter Hedlund on 9/25/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "UIImage+PHColor.h"

@implementation UIImage (PHColor)

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 27);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
