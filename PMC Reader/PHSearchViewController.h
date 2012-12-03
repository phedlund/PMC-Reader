//
//  PHSearchViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 11/19/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PHSearchViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)doDone:(id)sender;

@end
