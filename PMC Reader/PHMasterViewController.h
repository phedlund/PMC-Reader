//
//  PHMasterViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHDetailViewController;

@interface PHMasterViewController : UITableViewController

@property (strong, nonatomic) PHDetailViewController *detailViewController;

@end
