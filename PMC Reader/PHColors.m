//
//  PHColors.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/4/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHColors.h"

#define kPHBackgroundColorArray        @[kPHWhiteBackgroundColor, kPHSepiaBackgroundColor, kPHNightBackgroundColor]
#define kPHCellBackgroundColorArray    @[kPHWhiteCellBackgroundColor, kPHSepiaCellBackgroundColor, kPHNightCellBackgroundColor]
#define kPHIconColorArray              @[kPHWhiteIconColor, kPHSepiaIconColor, kPHNightIconColor]
#define kPHTextColorArray              @[kPHWhiteTextColor, kPHSepiaTextColor, kPHNightTextColor]
#define kPHLinkColorArray              @[kPHWhiteLinkColor, kPHSepiaLinkColor, kPHNightLinkColor]
#define kPHPopoverBackgroundColorArray @[kPHWhitePopoverBackgroundColor, kPHSepiaPopoverBackgroundColor, kPHNightPopoverBackgroundColor]
#define kPHPopoverButtonColorArray     @[kPHWhitePopoverButtonColor, kPHSepiaPopoverButtonColor, kPHNightPopoverButtonColor]
#define kPHPopoverBorderColorArray     @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightPopoverBorderColor]

@implementation PHColors

+ (UIColor *)backgroundColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)cellBackgroundColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHCellBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)iconColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHIconColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)textColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHTextColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)linkColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHLinkColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverBackgroundColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHPopoverBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverButtonColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHPopoverButtonColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverBorderColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    return [kPHPopoverBorderColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverIconColor {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    if (backgroundIndex == 2) {
        return kPHNightTextColor;
    }
    return [kPHIconColorArray objectAtIndex:backgroundIndex];
}

+ (UIImage *)changeImage:(UIImage*)image toColor:(UIColor*)color {
    CGRect rect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);

    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:img.CGImage scale:1.0 orientation: UIImageOrientationUp];
}

@end
