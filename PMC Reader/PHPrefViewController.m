//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"

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
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
    //[backgroundSegmented setUnselectedItemColor:[UIColor clearColor]];
    [[[backgroundSegmented subviews] objectAtIndex:0] setTintColor:[UIColor blackColor]];
    [[[backgroundSegmented subviews] objectAtIndex:2] setTintColor:[UIColor blackColor]];
    
	[backgroundSegmented setSelectedSegmentIndex:[prefs integerForKey:@"Background"]];
    [fontSizeSegmented setSelectedSegmentIndex:[prefs integerForKey:@"FontSize"]];
    [lineHeightSegmented setSelectedSegmentIndex:[prefs integerForKey:@"LineHeight"]];
    [marginSegmented setSelectedSegmentIndex:[prefs integerForKey:@"Margin"]];
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
    NSString *setting = nil;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	//int newSize = 0;
    if (seg == backgroundSegmented) {
        //NSLog(@"BG: %d", newValue);
        setting = @"Background";
    }
    if (seg == fontSizeSegmented) {
        //NSLog(@"FS: %d", newValue);
        setting = @"FontSize";
    }
    if (seg == lineHeightSegmented) {
        //NSLog(@"LH: %d", newValue);
        setting = @"LineHeight";
    }
    if (seg == marginSegmented) {
        //NSLog(@"M: %d", newValue);
        setting = @"Margin";
    }
    
    [prefs setInteger:newValue forKey:setting];
    if (_delegate != nil) {
		[_delegate settingsChanged:setting newValue:newValue];
	}
}
@end
