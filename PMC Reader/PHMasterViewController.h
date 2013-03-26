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

@interface PHMasterViewController : UIViewController <UITableViewDataSource, UIAlertViewDelegate, PHDownloaderDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) PHDetailViewController *detailViewController;
@property (nonatomic, strong, readonly) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *addBarButtonItem;
@property (strong, nonatomic) NSMutableArray *articles;
@property (strong, nonatomic) NSMutableArray *filteredArticles;
@property (nonatomic, assign) bool isFiltered;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;

- (IBAction) doEdit:(id)sender;
- (IBAction) doAdd:(id)sender;
- (IBAction) doRedownload:(id)sender;

@end
