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
#import "LXReorderableCollectionViewFlowLayout.h"
#import "PHCollectionViewCell.h"

@interface PHMasterViewController : UICollectionViewController <LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, PHDownloaderDelegate, UISearchBarDelegate, PHCollectionViewCellDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) PHDetailViewController *detailViewController;
@property (nonatomic, strong, readonly) UIBarButtonItem *addBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *searchBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *layoutBarButtonItem;
@property (strong, nonatomic) NSMutableArray *articles;
@property (strong, nonatomic) NSMutableArray *filteredArticles;
@property (nonatomic, assign) bool isFiltered;
@property (strong, nonatomic, readonly) UISearchBar *searchBar;

- (IBAction) doAdd:(id)sender;
- (IBAction) doLayout:(id)sender;
- (IBAction) doSearch:(id)sender;

@end
