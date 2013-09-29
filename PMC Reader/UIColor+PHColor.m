//
//  UIColor+PHColor.m
//  PMC Reader
//
//  Created by Peter Hedlund on 9/29/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "UIColor+PHColor.h"

#define kPHBackgroundColorArray        @[kPHWhiteBackgroundColor, kPHSepiaBackgroundColor, kPHNightBackgroundColor]
#define kPHCellBackgroundColorArray    @[kPHWhiteCellBackgroundColor, kPHSepiaCellBackgroundColor, kPHNightCellBackgroundColor]
#define kPHIconColorArray              @[kPHWhiteIconColor, kPHSepiaIconColor, kPHNightIconColor]
#define kPHTextColorArray              @[kPHWhiteTextColor, kPHSepiaTextColor, kPHNightTextColor]
#define kPHLinkColorArray              @[kPHWhiteLinkColor, kPHSepiaLinkColor, kPHNightLinkColor]
#define kPHPopoverBackgroundColorArray @[kPHWhitePopoverBackgroundColor, kPHSepiaPopoverBackgroundColor, kPHNightPopoverBackgroundColor]
#define kPHPopoverButtonColorArray     @[kPHWhitePopoverButtonColor, kPHSepiaPopoverButtonColor, kPHNightPopoverButtonColor]
#define kPHPopoverBorderColorArray     @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightPopoverBorderColor]

@implementation UIColor (PHColor)

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

@end
