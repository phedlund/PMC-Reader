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
- (void)configureView;
@end

@implementation PHDetailViewController

#pragma mark - Managing the detail item
@synthesize articleView = _articleView;

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
    NSString* imagePath = [ [ NSBundle mainBundle] pathForResource:@"BackIconGray" ofType:@"png"];
    [myBackButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    [myBackButton sizeToFit];
    
    UIButton* myForwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myForwardButton addTarget:self action:@selector(doGoForward:) forControlEvents:UIControlEventTouchUpInside];
    imagePath = [ [ NSBundle mainBundle] pathForResource:@"FwdIconGray" ofType:@"png"];
    [myForwardButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    [myForwardButton sizeToFit];
    
    UIBarButtonItem* barButtonBack = [[UIBarButtonItem alloc] initWithCustomView:myBackButton];
    UIBarButtonItem* barButtonForward = [[UIBarButtonItem alloc] initWithCustomView:myForwardButton];
    
    NSArray *buttons = [NSArray arrayWithObjects:self.navigationItem.leftBarButtonItem, barButtonBack, barButtonForward, nil];
    
    //self.navigationItem.rightBarButtonItem = barButtonBack;
    self.navigationItem.leftBarButtonItems = buttons;
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
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

@end
