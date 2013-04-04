//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"
#import "QuartzCore/QuartzCore.h"

#define MIN_FONT_SIZE 11
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH 380
#define MAX_WIDTH 650

@interface PHPrefViewController ()

@end

@implementation PHPrefViewController
@synthesize backgroundSegmented;
@synthesize fontSizeSegmented;
@synthesize lineHeightSegmented;
@synthesize marginSegmented;
@synthesize paginationSegmented;
@synthesize tableView;
@synthesize fonts;
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
    self.fonts = [prefs arrayForKey:@"Fonts"];

    //Did not work putting on storyboard
    CGRect tableViewFrame = CGRectMake(20, 20, 200, 283);
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    self.tableView.layer.borderWidth = 0.75;
    self.tableView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.tableView.layer.cornerRadius = 5;
    self.tableView.clipsToBounds = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 44.0;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [self setBackgroundSegmented:nil];
    [self setFontSizeSegmented:nil];
    [self setLineHeightSegmented:nil];
    [self setMarginSegmented:nil];
    [self setTableView:nil];
    [self setPaginationSegmented:nil];
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
    if (seg == paginationSegmented) {
        //NSLog(@"BG: %d", newValue);
        setting = @"Paginate";
        [prefs setInteger:newValue forKey:setting];
    }
    
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
   
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView reloadData];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[self.fonts objectAtIndex:indexPath.row] forKey:@"Font"];
    if (_delegate != nil) {
		[_delegate settingsChanged:@"Font" newValue:indexPath.row];
	}
}

@end
