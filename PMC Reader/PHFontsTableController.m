//
//  PHFontsTableControllerViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 10/5/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHFontsTableController.h"
#import "UIColor+PHColor.h"

@interface PHFontsTableController ()

@end

@implementation PHFontsTableController

@synthesize fonts;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        self.fonts = [prefs arrayForKey:@"Fonts"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    self.tableView.separatorColor = [UIColor popoverBorderColor];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FontCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [self.fonts objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *font = [prefs valueForKey:@"Font"];
    NSInteger currentIndex = [self.fonts indexOfObject:font];
    if (currentIndex == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.backgroundColor = [UIColor popoverButtonColor];
    cell.textLabel.textColor = [UIColor popoverIconColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView reloadData];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[self.fonts objectAtIndex:indexPath.row] forKey:@"Font"];
    if (_delegate != nil) {
		[_delegate fontSelected:indexPath.row];
	}
}

@end
