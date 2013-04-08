//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "PHColors.h"

#define MIN_FONT_SIZE 11
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH 380
#define MAX_WIDTH 650

@interface PHPrefViewController ()

@end

@implementation PHPrefViewController
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
    
    [self.paginationOnButton.layer setCornerRadius:8.0f];
    [self.paginationOnButton.layer setMasksToBounds:YES];
    [self.paginationOnButton.layer setBorderWidth:0.75f];
    [self.paginationOnButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.paginationOffButton.layer setCornerRadius:8.0f];
    [self.paginationOffButton.layer setMasksToBounds:YES];
    [self.paginationOffButton.layer setBorderWidth:0.75f];
    [self.paginationOffButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.decreaseFontSizeButton.layer setMasksToBounds:YES];
    [self.decreaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.decreaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.increaseFontSizeButton.layer setMasksToBounds:YES];
    [self.increaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.increaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.whiteBackgroundButton.layer setCornerRadius:8.0f];
    [self.whiteBackgroundButton.layer setMasksToBounds:YES];
    [self.whiteBackgroundButton.layer setBorderWidth:0.75f];
    [self.whiteBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.sepiaBackgroundButton.layer setCornerRadius:8.0f];
    [self.sepiaBackgroundButton.layer setMasksToBounds:YES];
    [self.sepiaBackgroundButton.layer setBorderWidth:0.75f];
    [self.sepiaBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.nightBackgroundButton.layer setCornerRadius:8.0f];
    [self.nightBackgroundButton.layer setMasksToBounds:YES];
    [self.nightBackgroundButton.layer setBorderWidth:0.75f];
    [self.nightBackgroundButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.decreaseLineHeightButton.layer setMasksToBounds:YES];
    [self.decreaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.decreaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.increaseLineHeightButton.layer setMasksToBounds:YES];
    [self.increaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.increaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseMarginButton.layer setCornerRadius:8.0f];
    [self.decreaseMarginButton.layer setMasksToBounds:YES];
    [self.decreaseMarginButton.layer setBorderWidth:0.75f];
    [self.decreaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseMarginButton.layer setCornerRadius:8.0f];
    [self.increaseMarginButton.layer setMasksToBounds:YES];
    [self.increaseMarginButton.layer setBorderWidth:0.75f];
    [self.increaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self updateBackgrounds];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setPaginationOnButton:nil];
    [self setPaginationOffButton:nil];
    [self setWhiteBackgroundButton:nil];
    [self setSepiaBackgroundButton:nil];
    [self setNightBackgroundButton:nil];
    [self setDecreaseFontSizeButton:nil];
    [self setIncreaseFontSizeButton:nil];
    [self setDecreaseLineHeightButton:nil];
    [self setIncreaseLineHeightButton:nil];
    [self setDecreaseMarginButton:nil];
    [self setIncreaseMarginButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updateBackgrounds {
    UIColor *bgColor = [PHColors backgroundColor];
    self.view.backgroundColor = bgColor;
    self.tableView.backgroundColor = bgColor;
    
    self.paginationOnButton.backgroundColor = bgColor;
    self.paginationOffButton.backgroundColor = bgColor;
    self.decreaseFontSizeButton.backgroundColor = bgColor;
    self.increaseFontSizeButton.backgroundColor = bgColor;
    self.whiteBackgroundButton.backgroundColor = [UIColor whiteColor];
    self.sepiaBackgroundButton.backgroundColor = [PHColors colorFromHexString:@"#F5EFDC"];
    self.nightBackgroundButton.backgroundColor = [UIColor blackColor];
    self.decreaseLineHeightButton.backgroundColor = bgColor;
    self.increaseLineHeightButton.backgroundColor = bgColor;
    self.decreaseMarginButton.backgroundColor = bgColor;
    self.increaseMarginButton.backgroundColor = bgColor;
    
    [self.tableView reloadData];
  
}

- (IBAction)handleButtonTap:(UIButton *)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (sender == self.paginationOnButton) {
        [prefs setInteger:1 forKey:@"Paginate"];
    }

    if (sender == self.paginationOffButton) {
        [prefs setInteger:0 forKey:@"Paginate"];
    }

    if (sender == self.whiteBackgroundButton) {
        [prefs setInteger:0 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.sepiaBackgroundButton) {
        [prefs setInteger:1 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.nightBackgroundButton) {
        [prefs setInteger:2 forKey:@"Background"];
        [self updateBackgrounds];
    }

    if (sender == self.decreaseFontSizeButton) {
        int currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        
        if (currentFontSize > MIN_FONT_SIZE) {
            --currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (sender == self.increaseFontSizeButton) {
        int currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        if (currentFontSize < MAX_FONT_SIZE) {
            ++currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    
    if (sender == self.decreaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight > MIN_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight - 0.2f;
        }
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }

    if (sender == self.increaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight < MAX_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight + 0.2f;
        }    
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }
    
    if (sender == self.decreaseMarginButton) {
        int currentMargin = [[prefs valueForKey:@"Margin"] integerValue];
        if (currentMargin < MAX_WIDTH) {
            currentMargin = currentMargin + 20;
        }
        [prefs setInteger:currentMargin forKey:@"Margin"];
    }
    
    if (sender == self.increaseMarginButton) {
        int currentMargin = [[prefs valueForKey:@"Margin"] integerValue];
        if (currentMargin > MIN_WIDTH) {
            currentMargin = currentMargin - 20;
        }
        [prefs setInteger:currentMargin forKey:@"Margin"];
    }
    
    [prefs synchronize];

    if (_delegate != nil) {
		[_delegate settingsChanged:@"" newValue:0];
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
    cell.textLabel.textColor = [PHColors textColor];
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
