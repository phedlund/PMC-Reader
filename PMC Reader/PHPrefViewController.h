//
//  PHPrefViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSegmentedControl.h"

@protocol PHPrefViewControllerDelegate
- (void)settingsChanged:(NSString*)setting newValue:(NSUInteger)value;
@end

@interface PHPrefViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet MCSegmentedControl *paginationSegmented;
@property (weak, nonatomic) IBOutlet UISegmentedControl *backgroundSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *fontSizeSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *lineHeightSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *marginSegmented;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *fonts;

@property (nonatomic, strong) id<PHPrefViewControllerDelegate> delegate;

- (IBAction)doSegmentedValueChanged:(id)sender;

@end
