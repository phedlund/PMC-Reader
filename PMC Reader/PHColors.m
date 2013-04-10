//
//  PHColors.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/4/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHColors.h"

@implementation PHColors


// Assumes input like "#00FF00" (#RRGGBB).
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor {
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    return [self colorFromHexString:background];
}

+ (NSString *)backgroundColorAsHex {
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [backgrounds objectAtIndex:backgroundIndex];
}

+ (UIColor *)textColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Colors"];
    NSString *color = [colors objectAtIndex:backgroundIndex];
    return [self colorFromHexString:color];
}

+ (NSString *)textColorAsHex {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Colors"];
    return [colors objectAtIndex:backgroundIndex];    
}

+ (UIColor *)linkColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ColorsLink"];
    NSString *color = [colors objectAtIndex:backgroundIndex];
    return [self colorFromHexString:color];
}

+ (NSString *)linkColorAsHex {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ColorsLink"];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIImage *)changeImage:(UIImage*)image toColor:(UIColor*)color {
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:img.CGImage scale:1.0 orientation: UIImageOrientationDownMirrored];
}

@end
