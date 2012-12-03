//
//  PHMasterViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHDetailViewController.h"
#import "PHDownloader.h"

@interface PHMasterViewController : UIViewController <UITableViewDataSource, UIAlertViewDelegate, PHDownloaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) PHDetailViewController *detailViewController;
@property (strong, nonatomic) NSMutableArray *articles;

- (IBAction)doAdd:(id)sender;

@end
