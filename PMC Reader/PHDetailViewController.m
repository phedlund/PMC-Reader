//
//  PHDetailViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import "PHDetailViewController.h"
#import "IIViewDeckController.h"
#import "PHArticle.h"
#import "PHArticleNavigationItem.h"
#import "PHArticleReference.h"
#import "TransparentToolbar.h"
#import "PHColors.h"

#define TITLE_LABEL_WIDTH_LANDSCAPE 700
#define TITLE_LABEL_WIDTH_PORTRAIT 450

@interface PHDetailViewController () {
    PopoverView *popover;
    CGPoint currentTapLocation;
    int _pageCount;
    int _currentPage;
}

@property (strong, nonatomic) UIPopoverController *prefPopoverController;
@property (strong, nonatomic) PHPrefViewController *prefViewController;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *pageTapRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *nextPageSwipeRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *previousPageSwipeRecognizer;

- (void) configureView;
- (void) updatePagination;
- (BOOL) shouldPaginate;
- (void) gotoPage:(int)page animated:(BOOL)animated;
- (void) updateBackgrounds;

@end

@implementation PHDetailViewController

@synthesize articleView = _articleView;
@synthesize prefPopoverController = _prefPopoverController;
@synthesize prefViewController = _prefViewController;
@synthesize titleLabel, titleBarButtonItem;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, leftToolbar;
@synthesize infoBarButtonItem, prefsBarButtonItem, navBarButtonItem;
@synthesize articleNavigationController, articleNavigationPopover;
@synthesize pageTapRecognizer, nextPageSwipeRecognizer, previousPageSwipeRecognizer;
@synthesize pageNumberBar;

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
        [self updatePagination];
        if ([self articleView] != nil) {
            [[self articleView] removeFromSuperview];
            [self articleView].delegate =nil;
            self.articleView = nil;
        }
        self.articleView = [[UIWebView alloc] initWithFrame:[self articleRect]];
        self.articleView.scalesPageToFit = YES;
        self.articleView.delegate = self;
        self.articleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.articleView.alpha = 0;
        self.articleView.opaque = NO;
        self.articleView.backgroundColor = [PHColors backgroundColor];
        [self.view insertSubview:self.articleView belowSubview:self.pageBarContainerView];
        
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
        gesture.numberOfTapsRequired = 2;
        [self.articleView addGestureRecognizer:gesture];
        gesture.delegate = self;

        UITapGestureRecognizer *tapLocationGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateTapLocation:)];
        tapLocationGesture.numberOfTapsRequired = 1;
        [self.articleView addGestureRecognizer:tapLocationGesture];
        tapLocationGesture.delegate = self;

        _currentPage = 0;
        self.pageNumberLabel.text = @"";
        
        
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
        [self updateBackgrounds];
        //[[self navigationItem] setTitle:[detail objectForKey:@"Title"]];
        [self.titleLabel setText:detail.title];
        [self.titleLabel2 setText:detail.title];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.wantsFullScreenLayout = YES;
    self.viewDeckController.delegate = self;
    self.viewDeckController.panningView = self.topContainerView;
    [[self navigationItem] setTitle:@""];
    [self updateToolbar];
    [self configureView];
    currentTapLocation = CGPointMake(350, 100);
    self.titleLabel2.text = @"";
    self.pageNumberLabel.text = @"";
    self.navigationController.navigationBar.translucent = YES;
    [self updateBackgrounds];
}

- (void)viewDidUnload
{
    [self setArticleView:nil];
    [self setPageBarContainerView:nil];
    [self setTopContainerView:nil];
    [self setPageNumberLabel:nil];
    [self setTitleLabel2:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CGRect newRect = self.titleLabel.frame;
    CGRect newRect2 = self.titleLabel2.frame;
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
        ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
        newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
        newRect2.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
    } else {
        newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
        newRect2.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
    }
    self.titleLabel.frame = newRect;
    self.titleLabel2.frame = newRect2;
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    CGRect newRect = self.titleLabel.frame;
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
    } else {
        newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
    }
    self.titleLabel.frame = newRect;
    if ([self shouldPaginate]) {
        if (self.articleView != nil) {
            [self.articleView reload];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (popover) {
        [popover dismiss:NO];
    }
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
    
    [_prefPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (IBAction)doInfo:(id)sender {
    if (self.detailItem != nil) {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", @"Copy", nil];
        [menu showFromBarButtonItem:infoBarButtonItem animated:YES];
    }
}

- (IBAction) doNavigation:(id)sender {
    PHArticle *detail = (PHArticle *) self.detailItem;
    self.articleNavigationController.articleSections = [NSArray arrayWithArray:detail.articleNavigationItems];
    if (detail.articleNavigationItems.count > 0) {
        self.articleNavigationPopover.popoverContentSize  = CGSizeMake(290.0f, 44 * detail.articleNavigationItems.count);
    } else {
        self.articleNavigationPopover.popoverContentSize = CGSizeMake(290.0f, 44);
    }

    [self.articleNavigationPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (PHArticleNavigationControllerViewController *) articleNavigationController {
    if (!articleNavigationController) {
        articleNavigationController = [[PHArticleNavigationControllerViewController alloc] initWithStyle:UITableViewStylePlain];
        articleNavigationController.delegate = self;
    }
    return articleNavigationController;
}

- (UIPopoverController *) articleNavigationPopover {
    if (!articleNavigationPopover) {
        articleNavigationPopover = [[UIPopoverController alloc] initWithContentViewController:self.articleNavigationController];
    }
    return articleNavigationPopover;
}

- (void)toggleNavBar:(UITapGestureRecognizer *)gesture {
    CGPoint loc = [gesture locationInView:self.articleView];
    double w = self.articleView.frame.size.width;
    if ((loc.x > 150) && (loc.x < (w - 150))) {
        if (self.navigationController.navigationBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = NO;
            self.viewDeckController.leftController.view.frame = [self orientationRect];
            self.pageNumberBar.hidden = NO;
            self.pageNumberLabel.alpha = 1.0f;
            self.titleLabel2.hidden = YES;
            if (![self shouldPaginate]) {
                [self.articleView setFrame:CGRectMoveTop(self.view.frame, 64)];
                self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
            } else {
                self.viewDeckController.panningMode = IIViewDeckNavigationBarPanning;
            }
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = YES;
            self.pageNumberBar.hidden = YES;
            self.pageNumberLabel.alpha = 0.5f;
            CGRect r = [self orientationRect];
            self.viewDeckController.leftController.view.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height + 20.0);
            self.titleLabel2.hidden = NO;
            if (![self shouldPaginate]) {
                [self.articleView setFrame:self.view.frame];
                self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
            } else {
                self.viewDeckController.panningMode = IIViewDeckPanningViewPanning;
            }
        }
    }
}

- (CGRect)orientationRect {
    CGFloat width;
    CGFloat height;
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
           ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
        width = screen.height;
        height = screen.width;
    } else {
        width = screen.width;
        height = screen.height;
    }
    return CGRectMake(0.0, 0.0, width, height);
}

- (CGRect)articleRect {
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
        ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
        return CGRectMake(0, 84, 1024, 600);
    } else {
        return CGRectMake(0, 84, 768, 846);
    }
}

- (CGRect)pageNumberBarRect {
    int width =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
    int x = ([self orientationRect].size.width - width) / 2;
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
        ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
        return CGRectMake(x, 20, width, 30);
    } else {
        return CGRectMake(x, 20, width, 30);
    }
}

- (void) updateTapLocation:(UIGestureRecognizer *)gestureRecognizer {
    currentTapLocation = [gestureRecognizer locationInView:self.articleView];
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (viewDeckSide == IIViewDeckLeftSide) {
        if (self.navigationController.navigationBarHidden) {
            [self toggleNavBar:nil];
        }
    }
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self.articleView.request.URL.scheme isEqualToString:@"file"]) {
        if ([request.URL.scheme isEqualToString:@"http"]) {
            NSRange range = [request.URL.absoluteString rangeOfString:@"#"];
            if (range.location != NSNotFound) {
                PHArticle *detail = (PHArticle *) self.detailItem;
                if (detail.references.count > 0) {
                    __block BOOL refFound = NO;
                    [detail.references enumerateObjectsUsingBlock:^(PHArticleReference *ref, NSUInteger idx, BOOL *stop) {
                        if ([ref.idAttribute isEqualToString:[request.URL fragment]]) {
                            NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
                            NSURL *url = [NSURL URLWithString:[frag stringByAppendingString:[request.URL fragment]] relativeToURL:self.articleView.request.URL];
                            NSString *labelText = [NSString stringWithFormat:@" [<a href='%@'>Ref List</a>]", [url absoluteString]];
                            labelText = [ref.text stringByAppendingString:labelText];
                            
                            RTLabel *label = [[RTLabel alloc] initWithFrame:CGRectMake(0, 0, 350, 500)];
                            label.delegate = self;
                            label.text = labelText;
                            CGSize opt = [label optimumSize];
                            CGRect frame = [label frame];
                            frame.size.height = (int)opt.height+5;
                            [label setFrame:frame];

                            popover = [PopoverView showPopoverAtPoint:currentTapLocation inView:self.articleView withContentView:label delegate:self];
                            //NSLog(@"Visible: %@", label.visibleText);
                            refFound = YES;
                            *stop = YES;
                        }
                    }];
                    if (!refFound) {
                        NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
                        NSURL *url = [NSURL URLWithString:[frag stringByAppendingString:[request.URL fragment]] relativeToURL:self.articleView.request.URL];
                        [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
                    }
                } else {
                     NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
                     NSURL *url = [NSURL URLWithString:[frag stringByAppendingString:[request.URL fragment]] relativeToURL:self.articleView.request.URL];
                     [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
                }
                return NO;
            }
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbar];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    self.titleLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.titleLabel2.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self updatePagination];
    [UIView animateWithDuration:0.30 animations:^{
        webView.alpha = 1;
    }];
    
    [self updateToolbar];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url {
    if (popover) {
        [popover dismiss:NO];
    }
    [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)popoverViewDidDismiss:(PopoverView *)popoverView {
    popover = nil;
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateBackgrounds" object:nil userInfo:nil];
    [self updateBackgrounds];
    [self writeCssTemplate];
    [self updatePagination];
    if ([self articleView] != nil) {
        [self.articleView reload];
    }
    self.pageNumberBar.frame = [self pageNumberBarRect];
}

- (void)updateBackgrounds {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    UIColor *bgColor = [PHColors backgroundColor];
    self.viewDeckController.view.backgroundColor = bgColor;
    self.view.backgroundColor = bgColor;
    self.topContainerView.backgroundColor = bgColor;
    self.pageBarContainerView.backgroundColor = bgColor;
    if (self.articleView) {
        self.articleView.backgroundColor = bgColor;
    }
    self.pageNumberBar.nightMode = (backgroundIndex == 2);
    self.titleLabel2.alpha = (backgroundIndex == 2) ? 1.0f : 0.5f;
    self.titleLabel.textColor = [PHColors textColor];
}

- (void) writeCssTemplate
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"pmc_template" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    NSString *font = [[NSUserDefaults standardUserDefaults] objectForKey:@"Font"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONT$" withString:font];

    int fontSize =[[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONTSIZE$" withString:[NSString stringWithFormat:@"%dpx", fontSize]];
    
    int margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%dpx", margin]];
    
    double lineHeight =[[NSUserDefaults standardUserDefaults] doubleForKey:@"LineHeight"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%fem", lineHeight]];
    
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:[PHColors backgroundColorAsHex]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:[PHColors textColorAsHex]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:[PHColors linkColorAsHex]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    docDir = [docDir URLByAppendingPathComponent:@"templates" isDirectory:YES];
    
    [cssTemplate writeToURL:[docDir URLByAppendingPathComponent:@"pmc.css"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)updateCSS {
    NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
    
    NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
    "if (mySheet.addRule) {"
    "mySheet.addRule(selector, newRule);"								// For Internet Explorer
    "} else {"
    "ruleIndex = mySheet.cssRules.length;"
    "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
    "}"
    "}";
    
    NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", [self articleRect].size.height, [self articleRect].size.width];
    //NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
    //NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", 100];
    //NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];
    
    [self.articleView stringByEvaluatingJavaScriptFromString:varMySheet];
    [self.articleView stringByEvaluatingJavaScriptFromString:addCSSRule];
    [self.articleView stringByEvaluatingJavaScriptFromString:insertRule1];
    //[self.articleView stringByEvaluatingJavaScriptFromString:insertRule2];
    //[self.articleView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    //[self.articleView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];

    //if(currentSearchResult!=nil){
    //	NSLog(@"Highlighting %@", currentSearchResult.originatingQuery);
    //    [webView highlightAllOccurencesOfString:currentSearchResult.originatingQuery];
    //}    
    
    int totalWidth = [[self.articleView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
    int oldPageCount = _pageCount;
    _pageCount = (int)((float)totalWidth/self.articleView.bounds.size.width);
    float ratio = (float)_pageCount/(float)oldPageCount;
    _currentPage = (int)(_currentPage * ratio);
    self.pageNumberBar.maximumValue = _pageCount - 1;
    self.pageNumberLabel.text = [NSString stringWithFormat:@"%d/%d",_currentPage + 1, _pageCount];
    [self gotoPage:_currentPage animated:NO];
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

#pragma mark - Page navigation

- (UITapGestureRecognizer *) pageTapRecognizer {
    if (!pageTapRecognizer) {
        pageTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        pageTapRecognizer.numberOfTapsRequired = 1;
        pageTapRecognizer.delegate = self;
    }
    return pageTapRecognizer;
}

- (UISwipeGestureRecognizer *) nextPageSwipeRecognizer {
    if (!nextPageSwipeRecognizer) {
        nextPageSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        nextPageSwipeRecognizer.numberOfTouchesRequired = 1;
        nextPageSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        nextPageSwipeRecognizer.delegate = self;
    }
    return nextPageSwipeRecognizer;
}

- (UISwipeGestureRecognizer *) previousPageSwipeRecognizer {
    if (!previousPageSwipeRecognizer) {
        previousPageSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        previousPageSwipeRecognizer.numberOfTouchesRequired = 1;
        previousPageSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        previousPageSwipeRecognizer.delegate = self;
    }
    return previousPageSwipeRecognizer;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint loc = [gesture locationInView:self.articleView];
        int contentWidth =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
        double viewWidth = self.articleView.frame.size.width;
        int margin = (viewWidth - contentWidth) / 2;
        if (loc.x < margin) {
            [self gotoPage:--_currentPage animated:YES];
        }
        if (loc.x > (viewWidth - margin)) {
            [self gotoPage:++_currentPage animated:YES];
        }
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
            [self gotoPage:++_currentPage animated:YES];
        }
        if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
            [self gotoPage:--_currentPage animated:YES];
        }
    }
}

- (void) gotoPage:(int)page animated:(BOOL)animated {
    if (page < 0) {
        _currentPage = 0;
        return;
    }
    if (page > (_pageCount - 1)) {
        _currentPage = _pageCount - 1;
        return;
    }
    
    _currentPage = page;
    float pageOffset = _currentPage * self.articleView.bounds.size.width;
    [self.articleView.scrollView setContentOffset:CGPointMake(pageOffset, 0.0f) animated:animated];

    self.pageNumberBar.value = _currentPage;
	self.pageNumberLabel.text = [NSString stringWithFormat:@"%d/%d", _currentPage + 1, _pageCount];
}

- (SCPageScrubberBar *)pageNumberBar
{
    if (pageNumberBar == nil) {
        pageNumberBar = [[SCPageScrubberBar alloc] initWithFrame:[self pageNumberBarRect]];
        pageNumberBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        pageNumberBar.delegate = self;
        pageNumberBar.minimumValue = 0;
        pageNumberBar.maximumValue = 100;
        pageNumberBar.isPopoverMode = YES;
        pageNumberBar.alwaysShowTitleView = NO;
        pageNumberBar.nightMode = NO;
    }
    return pageNumberBar;
}

- (NSString*)scrubberBar:(SCPageScrubberBar*)scrubberBar titleTextForValue:(CGFloat)value {
    //NSInteger current = (int)value + 1;
    //return [NSString stringWithFormat:@"Page %d", current];
    return nil;
}

- (NSString *)scrubberBar:(SCPageScrubberBar *)scrubberBar subtitleTextForValue:(CGFloat)value {
    NSInteger current = (int)value + 1;
    return [NSString stringWithFormat:@"Page %d", current];
    //return @"";
}

- (void)scrubberBar:(SCPageScrubberBar*)scrubberBar valueSelected:(CGFloat)value {
    [self gotoPage:(int)value animated:NO];
}

- (BOOL)shouldPaginate {
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"Paginate"] == 1) {
        PHArticle *detail = (PHArticle *) self.detailItem;
        NSURL *url = self.articleView.request.URL;
        if ([[url absoluteString] hasSuffix:[NSString stringWithFormat:@"Documents/%@/text.html", detail.pmcId]]) {
            return YES;
        }
    }
    return NO;
}

- (void)updatePagination {
    if ([self shouldPaginate]) {
        if (self.articleView) {
            self.articleView.scrollView.scrollEnabled = NO;
            self.articleView.scrollView.bounces = NO;
            [self.articleView addGestureRecognizer:self.pageTapRecognizer];
            [self.articleView addGestureRecognizer:self.nextPageSwipeRecognizer];
            [self.articleView addGestureRecognizer:self.previousPageSwipeRecognizer];
            if (self.navigationController.navigationBarHidden) {
                self.viewDeckController.panningMode = IIViewDeckPanningViewPanning;
            } else {
                self.viewDeckController.panningMode = IIViewDeckNavigationBarPanning;
            }
            self.pageNumberBar.hidden = NO;
            self.titleLabel2.hidden = NO;
            self.articleView.frame = [self articleRect];
            [self updateCSS];
        } else {
            self.pageNumberBar.hidden = YES;
            self.titleLabel2.hidden = YES;
        }
        self.pageBarContainerView.hidden = NO;
        [self.pageBarContainerView addSubview:self.pageNumberBar];
        self.pageNumberBar.frame = [self pageNumberBarRect];
        self.topContainerView.hidden = NO;
        self.navigationController.navigationBar.autoresizesSubviews = NO;
    } else {
        if (self.articleView) {
            self.articleView.scrollView.scrollEnabled = YES;
            self.articleView.scrollView.bounces = YES;
            [self.articleView removeGestureRecognizer:self.pageTapRecognizer];
            [self.articleView removeGestureRecognizer:self.nextPageSwipeRecognizer];
            [self.articleView removeGestureRecognizer:self.previousPageSwipeRecognizer];
            self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
            [self.articleView setFrame:CGRectMoveTop(self.view.frame, 64)];
        }
        self.pageBarContainerView.hidden = YES;
        [self.pageNumberBar removeFromSuperview];
        self.topContainerView.hidden = NO;
        self.navigationController.navigationBar.autoresizesSubviews = YES;
    }
}

// Will return a CGRect with its upper boundary moved dy pixels, positive dy will reduce height, negative values increase
CGRect CGRectMoveTop(CGRect rect, CGFloat dy) {
    return CGRectMake(rect.origin.x, rect.origin.y + dy, rect.size.width, rect.size.height - dy);
}

// Will return a CGRect with its lower boundary moved dy pixels, positive values will reduce height, negative values increase
CGRect CGRectMoveBottom(CGRect rect, CGFloat dy) {
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - dy);
}

#pragma mark - Toolbar buttons


- (UILabel *) titleLabel {
    if (!titleLabel) {
        titleLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TITLE_LABEL_WIDTH_PORTRAIT, 44)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:16.0];
        titleLabel.textAlignment = UITextAlignmentLeft;
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.text = NSLocalizedString(@"Select an article", @"");
        titleLabel.autoresizingMask = UIViewAutoresizingNone;
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
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoBack:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!forwardBarButtonItem) {        
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoForward:)];
        forwardBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
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
        prefsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"text"] style:UIBarButtonItemStylePlain target:self action:@selector(doPreferences:)];
        prefsBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return prefsBarButtonItem;
}

- (UIBarButtonItem *)navBarButtonItem {
    if (!navBarButtonItem) {
        navBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contents"] style:UIBarButtonItemStylePlain target:self action:@selector(doNavigation:)];
        navBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);

    }
    return navBarButtonItem;
}

- (UIToolbar *) leftToolbar {
    if (!leftToolbar) {
        leftToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 125.0f, 44.0f)];
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
        self.prefsBarButtonItem.enabled = !self.articleView.isLoading;
        self.navBarButtonItem.enabled = !self.articleView.isLoading;
    } else {
        self.infoBarButtonItem.enabled = NO;
        self.prefsBarButtonItem.enabled = NO;
        self.navBarButtonItem.enabled = NO;
    }
    
    PHArticle *detail = (PHArticle *) self.detailItem;
    NSURL *url = self.articleView.request.URL;
    NSString *u = [url absoluteString];
    NSString *v = [NSString stringWithFormat:@"Documents/%@/text.html", detail.pmcId];
    
    if ([u rangeOfString:v].location == NSNotFound) {
        self.navBarButtonItem.enabled = NO;
    }
    
    v = [NSString stringWithFormat:@"Documents/%@", detail.pmcId];
    if ([u rangeOfString:v].location == NSNotFound) {
        self.prefsBarButtonItem.enabled = NO;
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
                           self.navBarButtonItem,
                           fixedSpace,
                           self.prefsBarButtonItem,
                           fixedSpace,
                           self.infoBarButtonItem,
                           fixedSpace,
                           nil];
    
    TransparentToolbar *toolbarRight = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 125, 44.0f)];
    toolbarRight.items = itemsRight;
    toolbarRight.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarRight];
}

- (void)articleSectionSelected:(NSUInteger)section {
    [self.articleNavigationPopover dismissPopoverAnimated:YES];
    PHArticle *detail = (PHArticle *) self.detailItem;
    PHArticleNavigationItem *navItem = (PHArticleNavigationItem *)[detail.articleNavigationItems objectAtIndex:section];
    NSURL *url = self.articleView.request.URL;
    NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
    [frag appendString:navItem.idAttribute];
    url = [NSURL URLWithString:frag relativeToURL:url];
    NSLog(@"DEBUG - absoluteString: %@", [url absoluteString]);
    [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
}

@end
