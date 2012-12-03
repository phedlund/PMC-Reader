//
//  PHDetailViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHDetailViewController.h"
#import "IIViewDeckController.h"
#import "PHArticle.h"

#define TITLE_LABEL_WIDTH 450

@interface PHDetailViewController ()

@property (strong, nonatomic) UIPopoverController *prefPopoverController;
@property (strong, nonatomic) PHPrefViewController *prefViewController;

- (void)configureView;

@end

@implementation PHDetailViewController

@synthesize articleView = _articleView;
@synthesize prefPopoverController = _prefPopoverController;
@synthesize prefViewController = _prefViewController;
@synthesize titleLabel, titleBarButtonItem;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, leftToolbar;
@synthesize infoBarButtonItem, prefsBarButtonItem;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }       
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        if ([self articleView] != nil) {
            [[self articleView] removeFromSuperview];
            [self articleView].delegate =nil;
            self.articleView = nil;
        }
        self.articleView = [[UIWebView alloc]initWithFrame:[self view].bounds];
        self.articleView.scalesPageToFit = YES;
        self.articleView.delegate = self;
        self.articleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [[self view] addSubview:self.articleView];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
        gesture.numberOfTapsRequired = 2;
        [self.articleView addGestureRecognizer:gesture];
        gesture.delegate = self;

        
        //self.detailDescriptionLabel.text = [self.detailItem objectAtIndex:0];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        PHArticle *detail = (PHArticle *) self.detailItem;
        docDir = [docDir URLByAppendingPathComponent:detail.pmcId isDirectory:YES];
        docDir = [docDir URLByAppendingPathComponent:@"text.html"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:docDir];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        //[[self articleView] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [[self articleView] loadRequest:request];
        //[[self navigationItem] setTitle:[detail objectForKey:@"Title"]];
        [self.titleLabel setText:detail.title];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@""];
    [self updateToolbar];
    [self configureView];
}

- (void)viewDidUnload
{
    [self setArticleView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)dealloc
{
    [self.articleView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.articleView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Actions

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
    
    [_prefPopoverController presentPopoverFromBarButtonItem:prefsBarButtonItem permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
        
}

- (IBAction)doInfo:(id)sender {
    if (self.detailItem != nil) {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", @"Copy", nil];
        [menu showFromBarButtonItem:infoBarButtonItem animated:YES];
    }
}

- (void)toggleNavBar:(UITapGestureRecognizer *)gesture {
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (IBAction)doReload:(id)sender {
    [self.articleView reload];
}

- (IBAction)doStop:(id)sender {
    [self.articleView stopLoading];
	[self updateToolbar];
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbar];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    self.titleLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self updateToolbar];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    NSLog(@"New Setting: %@ with value %d", setting, value);
    [self writeCssTemplate];
    if ([self articleView] != nil) {
        [self.articleView reload];
    }
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
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%dpx", (700 - [margin intValue])]];
    
    NSArray *lineHeights = [[NSUserDefaults standardUserDefaults] arrayForKey:@"LineHeights"];
    //NSLog(@"LineHeights: %@", lineHeights);
    int lineHeightIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"LineHeight"];
    NSString *lineHeight = [lineHeights objectAtIndex:lineHeightIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%@em", lineHeight]];
    
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    //NSLog(@"Backgrounds: %@", backgrounds);
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    //NSLog(@"BackgroundIndex: %d", backgroundIndex);
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    //NSLog(@"Background: %@", background);
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:background];
    
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Colors"];
    //backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    PHArticle *detail = (PHArticle *) self.detailItem;
    
    NSURL *url = self.articleView.request.URL;
    NSLog(@"URL: %@", [url absoluteString]);
    if ([[url absoluteString] hasSuffix:[NSString stringWithFormat:@"Documents/%@/text.html", detail.pmcId]]) {
        url = detail.url;
    }
    
    switch (buttonIndex) {
        case 0: {
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
        case 1: {
            UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:url.absoluteString];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Toolbar buttons


- (UILabel *) titleLabel {
    if (!titleLabel) {
        titleLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TITLE_LABEL_WIDTH, 44)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:16.0];
        //label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        titleLabel.textAlignment = UITextAlignmentLeft;
        titleLabel.textColor = [UIColor blackColor]; // change this color
        titleLabel.text = NSLocalizedString(@"Select an article", @"");
        titleLabel.autoresizingMask = UIViewAutoresizingNone;
        //[label sizeToFit];
    }
    return titleLabel;
}

- (UIBarButtonItem *) titleBarButtonItem {
    if (!titleBarButtonItem) {
        titleBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.titleLabel];
    }
    return titleBarButtonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!backBarButtonItem) {
        UIButton* myBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myBackButton addTarget:self action:@selector(doGoBack:) forControlEvents:UIControlEventTouchUpInside];
        [myBackButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [myBackButton sizeToFit];
        backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myBackButton];
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!forwardBarButtonItem) {        
        UIButton* myForwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myForwardButton addTarget:self action:@selector(doGoForward:) forControlEvents:UIControlEventTouchUpInside];
        [myForwardButton setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
        [myForwardButton sizeToFit];
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myForwardButton];
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!refreshBarButtonItem) {
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doReload:)];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!stopBarButtonItem) {
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(doStop:)];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)infoBarButtonItem {
    if (!infoBarButtonItem) {
        infoBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(doInfo:)];
    }
    return infoBarButtonItem;
}

- (UIBarButtonItem *)prefsBarButtonItem {
    if (!prefsBarButtonItem) {
        UIButton* myPrefsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myPrefsButton addTarget:self action:@selector(doPreferences:) forControlEvents:UIControlEventTouchUpInside];
        [myPrefsButton setImage:[UIImage imageNamed:@"gear"] forState:UIControlStateNormal];
        [myPrefsButton sizeToFit];
        prefsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myPrefsButton];
    }
    return prefsBarButtonItem;
}

- (UIToolbar *) leftToolbar {
    if (!leftToolbar) {
        leftToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 125.0f, 44.0f)];
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 5.0f;

        NSArray *itemsLeft = [NSArray arrayWithObjects:
                                        fixedSpace,
                                        self.backBarButtonItem,
                                        fixedSpace,
                                        self.forwardBarButtonItem,
                                        fixedSpace,
                                        fixedSpace,
                                        fixedSpace,
                                        self.titleBarButtonItem,
                                        nil];

        leftToolbar.items = itemsLeft;
        leftToolbar.tintColor = self.navigationController.navigationBar.tintColor;
    }
    return leftToolbar;
}


#pragma mark - Toolbar

- (void)updateToolbar {
    self.backBarButtonItem.enabled = self.articleView.canGoBack;
    self.forwardBarButtonItem.enabled = self.articleView.canGoForward;
    if ((self.detailItem != nil)) {
        self.infoBarButtonItem.enabled = !self.articleView.isLoading;
    } else {
        self.infoBarButtonItem.enabled = NO;
    }

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.articleView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    refreshStopBarButtonItem.enabled = (self.detailItem != nil);
    
    NSMutableArray *itemsLeft = [self.leftToolbar.items mutableCopy];
    
    [itemsLeft replaceObjectAtIndex:(itemsLeft.count - 3) withObject:refreshStopBarButtonItem];

    [self.leftToolbar setItems:itemsLeft];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftToolbar];

    NSArray *itemsRight = [NSArray arrayWithObjects:
                           fixedSpace,
                           self.infoBarButtonItem,
                           fixedSpace,
                           self.prefsBarButtonItem,
                           fixedSpace,
                           nil];
    
    UIToolbar *toolbarRight = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0, 44.0f)];
    toolbarRight.items = itemsRight;
    toolbarRight.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarRight];
}


@end
