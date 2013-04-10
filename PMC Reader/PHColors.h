//
//  PHColors.h
//  PMC Reader
//
//  Created by Peter Hedlund on 4/4/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PHColors : NSObject {
    
}

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIColor *)backgroundColor;
+ (NSString *)backgroundColorAsHex;
+ (UIColor *)textColor;
+ (NSString *)textColorAsHex;
+ (UIColor *)linkColor;
+ (NSString *)linkColorAsHex;
+ (UIImage *)changeImage:(UIImage*)image toColor:(UIColor*)color;

@end
