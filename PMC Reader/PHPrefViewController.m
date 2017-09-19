//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2017 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "UIColor+PHColor.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH 45 //%
#define MAX_WIDTH 95 //%

@implementation PHPrefViewController

@synthesize delegate = _delegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
    [self.paginationOnButton.layer setCornerRadius:8.0f];
    [self.paginationOnButton.layer setMasksToBounds:YES];
    [self.paginationOnButton.layer setBorderWidth:0.75f];
    [self.paginationOnButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.paginationOffButton.layer setCornerRadius:8.0f];
    [self.paginationOffButton.layer setMasksToBounds:YES];
    [self.paginationOffButton.layer setBorderWidth:0.75f];
    [self.paginationOffButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.decreaseFontSizeButton.layer setMasksToBounds:YES];
    [self.decreaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.decreaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.increaseFontSizeButton.layer setMasksToBounds:YES];
    [self.increaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.increaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.whiteBackgroundButton.layer setCornerRadius:8.0f];
    [self.whiteBackgroundButton.layer setMasksToBounds:YES];
    [self.whiteBackgroundButton.layer setBorderWidth:0.75f];
    [self.whiteBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.sepiaBackgroundButton.layer setCornerRadius:8.0f];
    [self.sepiaBackgroundButton.layer setMasksToBounds:YES];
    [self.sepiaBackgroundButton.layer setBorderWidth:0.75f];
    [self.sepiaBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.nightBackgroundButton.layer setCornerRadius:8.0f];
    [self.nightBackgroundButton.layer setMasksToBounds:YES];
    [self.nightBackgroundButton.layer setBorderWidth:0.75f];
    [self.nightBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.decreaseLineHeightButton.layer setMasksToBounds:YES];
    [self.decreaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.decreaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.increaseLineHeightButton.layer setMasksToBounds:YES];
    [self.increaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.increaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseMarginButton.layer setCornerRadius:8.0f];
    [self.decreaseMarginButton.layer setMasksToBounds:YES];
    [self.decreaseMarginButton.layer setBorderWidth:0.75f];
    [self.decreaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseMarginButton.layer setCornerRadius:8.0f];
    [self.increaseMarginButton.layer setMasksToBounds:YES];
    [self.increaseMarginButton.layer setBorderWidth:0.75f];
    [self.increaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBackgrounds];
}

- (void)viewDidUnload
{
    [self setPaginationOnButton:nil];
    [self setPaginationOffButton:nil];
    [self setWhiteBackgroundButton:nil];
    [self setSepiaBackgroundButton:nil];
    [self setNightBackgroundButton:nil];
    [self setDecreaseFontSizeButton:nil];
    [self setIncreaseFontSizeButton:nil];
    [self setDecreaseLineHeightButton:nil];
    [self setIncreaseLineHeightButton:nil];
    [self setDecreaseMarginButton:nil];
    [self setIncreaseMarginButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updateBackgrounds {
    self.view.backgroundColor = [UIColor popoverBackgroundColor];
    
    UIColor *buttonColor = [UIColor popoverButtonColor];
    self.paginationOnButton.backgroundColor = buttonColor;
    self.paginationOffButton.backgroundColor = buttonColor;
    self.decreaseFontSizeButton.backgroundColor = buttonColor;
    self.increaseFontSizeButton.backgroundColor = buttonColor;
    self.whiteBackgroundButton.backgroundColor = kPHWhiteBackgroundColor;
    self.sepiaBackgroundButton.backgroundColor = kPHSepiaBackgroundColor;
    self.nightBackgroundButton.backgroundColor = kPHNightBackgroundColor;
    self.decreaseLineHeightButton.backgroundColor = buttonColor;
    self.increaseLineHeightButton.backgroundColor = buttonColor;
    self.decreaseMarginButton.backgroundColor = buttonColor;
    self.increaseMarginButton.backgroundColor = buttonColor;
 
    CGColorRef borderColor = [[UIColor popoverBorderColor] CGColor];
    self.paginationOnButton.layer.borderColor = borderColor;
    self.paginationOffButton.layer.borderColor = borderColor;
    self.decreaseFontSizeButton.layer.borderColor = borderColor;
    self.increaseFontSizeButton.layer.borderColor = borderColor;
    self.whiteBackgroundButton.layer.borderColor = borderColor;
    self.sepiaBackgroundButton.layer.borderColor = borderColor;
    self.nightBackgroundButton.layer.borderColor = borderColor;
    self.decreaseLineHeightButton.layer.borderColor = borderColor;
    self.increaseLineHeightButton.layer.borderColor = borderColor;
    self.decreaseMarginButton.layer.borderColor = borderColor;
    self.increaseMarginButton.layer.borderColor = borderColor;
    
    UIColor *iconColor = [UIColor popoverIconColor];
    self.paginationOnButton.tintColor = iconColor;
    self.paginationOffButton.tintColor = iconColor;
    self.decreaseFontSizeButton.tintColor = iconColor;
    self.increaseFontSizeButton.tintColor = iconColor;
    self.decreaseLineHeightButton.tintColor = iconColor;
    self.increaseLineHeightButton.tintColor = iconColor;
    self.decreaseMarginButton.tintColor = iconColor;
    self.increaseMarginButton.tintColor = iconColor;
}

- (IBAction)handleButtonTap:(UIButton *)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (sender == self.paginationOnButton) {
        [prefs setInteger:1 forKey:@"Paginate"];
    }

    if (sender == self.paginationOffButton) {
        [prefs setInteger:0 forKey:@"Paginate"];
    }

    if (sender == self.whiteBackgroundButton) {
        [prefs setInteger:0 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.sepiaBackgroundButton) {
        [prefs setInteger:1 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.nightBackgroundButton) {
        [prefs setInteger:2 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.decreaseFontSizeButton) {
        NSInteger currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        
        if (currentFontSize > MIN_FONT_SIZE) {
            --currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (sender == self.increaseFontSizeButton) {
        NSInteger currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        if (currentFontSize < MAX_FONT_SIZE) {
            ++currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (sender == self.decreaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight > MIN_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight - 0.2f;
        }
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }

    if (sender == self.increaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight < MAX_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight + 0.2f;
        }    
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }
    
    if (sender == self.decreaseMarginButton) {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            NSInteger currentMargin = [[prefs valueForKey:@"MarginPortrait"] integerValue];
            if (currentMargin < MAX_WIDTH) {
                currentMargin += 5;
            }
            [prefs setInteger:currentMargin forKey:@"MarginPortrait"];
        } else {
            NSInteger currentMarginLandscape = [[prefs valueForKey:@"MarginLandscape"] integerValue];
            if (currentMarginLandscape < MAX_WIDTH) {
                currentMarginLandscape += 5;
            }
            [prefs setInteger:currentMarginLandscape forKey:@"MarginLandscape"];
        }
    }
    
    if (sender == self.increaseMarginButton) {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            NSInteger currentMargin = [[prefs valueForKey:@"MarginPortrait"] integerValue];
            if (currentMargin > MIN_WIDTH) {
                currentMargin -= 5;
            }
            [prefs setInteger:currentMargin forKey:@"MarginPortrait"];
        } else {
            NSInteger currentMarginLandscape = [[prefs valueForKey:@"MarginLandscape"] integerValue];
            if (currentMarginLandscape > MIN_WIDTH) {
                currentMarginLandscape -= 5;
            }
            [prefs setInteger:currentMarginLandscape forKey:@"MarginLandscape"];
        }
    }
    
    [prefs synchronize];

    if (_delegate != nil) {
		[_delegate settingsChanged:@"" newValue:0];
	}
}

@end
