//
//  PHDetailViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHDetailViewController.h"

@interface PHDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UIPopoverController *prefPopoverController;
@property (strong, nonatomic) PHPrefViewController *prefViewController;

- (void)configureView;

@end

@implementation PHDetailViewController

@synthesize articleView = _articleView;
@synthesize prefPopoverController = _prefPopoverController;
@synthesize prefViewController = _prefViewController;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        //self.detailDescriptionLabel.text = [self.detailItem objectAtIndex:0];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        docDir = [docDir URLByAppendingPathComponent:[self.detailItem objectAtIndex:1] isDirectory:YES];
        [[self articleView] loadRequest:[NSURLRequest requestWithURL:[docDir URLByAppendingPathComponent:@"text.html"]]];
        [[self navigationItem] setTitle:[self.detailItem objectAtIndex:0]];
        [(UILabel*)[[self navigationItem] titleView] setText:[self.detailItem objectAtIndex:0]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // this will appear as the title in the navigation bar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:16.0];
    //label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor blackColor]; // change this color
    self.navigationItem.titleView = label;
    label.text = NSLocalizedString(@"Select an article", @"");
    //[label sizeToFit];
    
    UIButton* myBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myBackButton addTarget:self action:@selector(doGoBack:) forControlEvents:UIControlEventTouchUpInside];
    NSString* imagePath = [ [ NSBundle mainBundle] pathForResource:@"back" ofType:@"png"];
    [myBackButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    [myBackButton sizeToFit];
    
    UIButton* myForwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myForwardButton addTarget:self action:@selector(doGoForward:) forControlEvents:UIControlEventTouchUpInside];
    imagePath = [ [ NSBundle mainBundle] pathForResource:@"forward" ofType:@"png"];
    [myForwardButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    [myForwardButton sizeToFit];
    
    UIBarButtonItem* barButtonBack = [[UIBarButtonItem alloc] initWithCustomView:myBackButton];
    UIBarButtonItem* barButtonForward = [[UIBarButtonItem alloc] initWithCustomView:myForwardButton];
    
    NSArray *buttons = [NSArray arrayWithObjects:self.navigationItem.leftBarButtonItem, barButtonBack, barButtonForward, nil];
    
    //self.navigationItem.rightBarButtonItem = barButtonBack;
    self.navigationItem.leftBarButtonItems = buttons;
    
    UIButton* myInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [myInfoButton addTarget:self action:@selector(doInfo:) forControlEvents:UIControlEventTouchUpInside];
    //NSString* imagePath = [ [ NSBundle mainBundle] pathForResource:@"BackIconGray" ofType:@"png"];
    //[myBackButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    //[myBackButton sizeToFit];
    
    UIButton* myPrefsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myPrefsButton addTarget:self action:@selector(doPreferences:) forControlEvents:UIControlEventTouchUpInside];
    imagePath = [ [ NSBundle mainBundle] pathForResource:@"gear" ofType:@"png"];
    [myPrefsButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    [myPrefsButton sizeToFit];
    
    UIBarButtonItem* barButtonInfo = [[UIBarButtonItem alloc] initWithCustomView:myInfoButton];
    UIBarButtonItem* barButtonPrefs = [[UIBarButtonItem alloc] initWithCustomView:myPrefsButton];
    
    buttons = [NSArray arrayWithObjects:barButtonPrefs, barButtonInfo, nil];
    
    //self.navigationItem.rightBarButtonItem = barButtonBack;
    self.navigationItem.rightBarButtonItems = buttons;

    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
    gesture.numberOfTapsRequired = 2;
    [self.articleView addGestureRecognizer:gesture];
    gesture.delegate = self;

    [[self articleView] loadHTMLString:@"<!DOCTYPE html><html><body></body></html>" baseURL:nil];
    [[self articleView] setDelegate:self];

    [self configureView];
}

- (void)viewDidUnload
{
    [self setArticleView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.articleView reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    barButtonItem.title = NSLocalizedString(@"Articles", @"Articles");
    [buttons addObject:barButtonItem];
    [buttons addObjectsFromArray:self.navigationItem.leftBarButtonItems];
    //[self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    [self.navigationItem setLeftBarButtonItems:buttons animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    NSMutableArray *buttons = [self.navigationItem.leftBarButtonItems mutableCopy];
    [buttons removeObject:barButtonItem];
    [self.navigationItem setLeftBarButtonItems:buttons animated:YES];
    self.masterPopoverController = nil;
}

- (IBAction)doGoBack:(id)sender
{
    if ([[self articleView] canGoBack]) {
        [[self articleView] goBack];
    }
}

- (IBAction)doGoForward:(id)sender
{
    if ([[self articleView] canGoForward]) {
        [[self articleView] goForward];
    }
}

- (IBAction)doPreferences:(id)sender {
    if (_prefViewController == nil) {
        _prefViewController =  [self.storyboard instantiateViewControllerWithIdentifier:@"preferences"];
        _prefViewController.delegate = self;
        _prefPopoverController = [[UIPopoverController alloc] initWithContentViewController:_prefViewController];
    } 
    
    [_prefPopoverController presentPopoverFromBarButtonItem:[self.navigationItem.rightBarButtonItems objectAtIndex:0] permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
        
}

- (IBAction)doInfo:(id)sender {
    //
}

- (void)toggleNavBar:(UITapGestureRecognizer *)gesture {
    BOOL barsHidden = self.navigationController.navigationBar.hidden;
    [self.navigationController setNavigationBarHidden:!barsHidden animated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Enable or disable back
    [(UIButton*)[self.navigationItem.leftBarButtonItems objectAtIndex:(self.navigationItem.leftBarButtonItems.count - 2)] setEnabled:[webView canGoBack]];
    
    // Enable or disable forward
    [(UIButton*)[self.navigationItem.leftBarButtonItems objectAtIndex:(self.navigationItem.leftBarButtonItems.count - 1)] setEnabled:[webView canGoForward]];
    
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    NSLog(@"New Setting: %@ with value %d", setting, value);
    [self writeCssTemplate];
    [self.articleView reload];
}

- (void) writeCssTemplate
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"pmc_template" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *fontSizes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"FontSizes"];
    int fontIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    NSNumber *fontSize = (NSNumber*)[fontSizes objectAtIndex:fontIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONTSIZE$" withString:[NSString stringWithFormat:@"%dpx", [fontSize intValue]]];
    
    NSArray *margins = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Margins"];
    int marginIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
    NSNumber *margin = (NSNumber*)[margins objectAtIndex:marginIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%dpx", [margin intValue]]];
    
    NSArray *lineHeights = [[NSUserDefaults standardUserDefaults] arrayForKey:@"LineHeights"];
    int lineHeightIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"LineHeight"];
    NSString *lineHeight = [lineHeights objectAtIndex:lineHeightIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%@em", lineHeight]];
    
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:background];
    
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Colors"];
    backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *color = [colors objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:color];
    
    NSArray *colorsLink = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ColorsLink"];
    //backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *colorLink = [colorsLink objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:colorLink];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    docDir = [docDir URLByAppendingPathComponent:@"templates" isDirectory:YES];
    
    [cssTemplate writeToURL:[docDir URLByAppendingPathComponent:@"pmc.css"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
