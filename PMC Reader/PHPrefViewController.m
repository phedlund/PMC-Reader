//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"

#define MIN_FONT_SIZE 11
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH 380
#define MAX_WIDTH 700

@interface PHPrefViewController ()

@end

@implementation PHPrefViewController
@synthesize backgroundSegmented;
@synthesize fontSizeSegmented;
@synthesize lineHeightSegmented;
@synthesize marginSegmented;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setBackgroundSegmented:nil];
    [self setFontSizeSegmented:nil];
    [self setLineHeightSegmented:nil];
    [self setMarginSegmented:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)doSegmentedValueChanged:(id)sender {
    MCSegmentedControl *seg = (MCSegmentedControl*)sender;
    int newValue = [seg selectedSegmentIndex];
    if (newValue == UISegmentedControlNoSegment) {
        return;
    }
    
    NSString *setting = nil;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	//int newSize = 0;
    if (seg == backgroundSegmented) {
        //NSLog(@"BG: %d", newValue);
        setting = @"Background";
        [prefs setInteger:newValue forKey:setting];
    }
    
    if (seg == fontSizeSegmented) {
        //NSLog(@"FS: %d", newValue);
        int currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        if (newValue == 0) {
            if (currentFontSize > MIN_FONT_SIZE) {
                --currentFontSize;
            }
        } else {
            if (currentFontSize < MAX_FONT_SIZE) {
                ++currentFontSize;
            }
        }
        NSLog(@"FS: %d", currentFontSize);
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (seg == lineHeightSegmented) {
        //NSLog(@"LH: %d", newValue);
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (newValue == 0) {
            if (currentLineHeight > MIN_LINE_HEIGHT) {
                currentLineHeight = currentLineHeight - 0.2f;
            }
        } else {
            if (currentLineHeight < MAX_LINE_HEIGHT) {
                currentLineHeight = currentLineHeight + 0.2f;
            }
        }
        NSLog(@"FS: %f", currentLineHeight);
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }
    
    if (seg == marginSegmented) {
        //NSLog(@"M: %d", newValue);
        int currentMargin = [[prefs valueForKey:@"Margin"] integerValue];
        if (newValue == 0) {
            if (currentMargin < MAX_WIDTH) {
                currentMargin = currentMargin + 20;
            }
        } else {
            if (currentMargin > MIN_WIDTH) {
                currentMargin = currentMargin - 20;
            }
        }
        NSLog(@"FS: %d", currentMargin);
        [prefs setInteger:currentMargin forKey:@"Margin"];
    }
    
    seg.selectedSegmentIndex = UISegmentedControlNoSegment;
    if (_delegate != nil) {
		[_delegate settingsChanged:setting newValue:newValue];
	}
}
@end
