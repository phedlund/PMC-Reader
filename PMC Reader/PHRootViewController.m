//
//  PHRootViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 10/24/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHRootViewController.h"

@implementation PHRootViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    self.leftController = [storyboard instantiateViewControllerWithIdentifier:@"master"];
    self.centerController = [storyboard instantiateViewControllerWithIdentifier:@"detail"];
    self.sizeMode = IIViewDeckLedgeSizeMode;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

@end
