//
//  PHDetailViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PHDetailViewController.h"
#import "PHArticle.h"
#import "PHArticleNavigationItem.h"
#import "PHArticleReference.h"
#import "UIColor+PHColor.h"
#import "UIColor+Expanded.h"
#import "PHFigTablePanel.h"
#import "TransparentToolbar.h"

#define TITLE_LABEL_WIDTH_LANDSCAPE 630
#define TITLE_LABEL_WIDTH_PORTRAIT 380

@interface PHDetailViewController () {
    CGPoint currentTapLocation;
    int _pageCount;
    int _currentPage;
    BOOL _handlingLink;
    BOOL _scrollingInternally;
    NSString *_currentHash;
    CALayer *bottomBorder;
    BOOL _newArticle;
    int _newArticlePage;
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

@synthesize article = _article;
@synthesize articleView = _articleView;
@synthesize prefPopoverController = _prefPopoverController;
@synthesize prefViewController = _prefViewController;
@synthesize titleLabel, titleBarButtonItem;
@synthesize backBarButtonItem, goBackBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem;
@synthesize infoBarButtonItem, prefsBarButtonItem, navBarButtonItem;
@synthesize articleNavigationController, articleNavigationPopover;
@synthesize pageTapRecognizer, nextPageSwipeRecognizer, previousPageSwipeRecognizer;
@synthesize pageNumberBar;
@synthesize referencePopover;
@synthesize referenceLabel;

#pragma mark - Managing the detail item

- (void)setArticle:(PHArticle *)article {
    if (_article != article) {
        _article = article;
        [[NSUserDefaults standardUserDefaults] setValue:_article.pmcId forKey:@"Reading"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // Update the view.
        [self configureView];
    }       
}

- (void)configureView {
    if (self.article) {
        _newArticle = YES;
        _newArticlePage = -1;
        if (self.article.currentPage != nil) {
            if ([self.article.currentPage integerValue] > -1) {
                _newArticlePage =[self.article.currentPage integerValue];
            }
        }
        [self updatePagination];
        if ([self articleView] != nil) {
            [[self articleView] removeFromSuperview];
            [self articleView].delegate =nil;
            self.articleView = nil;
        }
        self.articleView = [[UIWebView alloc] initWithFrame:[self articleRect]];
        self.articleView.scalesPageToFit = YES;
        self.articleView.delegate = self;
        self.articleView.scrollView.delegate = self;
        self.articleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.articleView.alpha = 0;
        self.articleView.opaque = NO;
        self.articleView.backgroundColor = [UIColor backgroundColor];
        [self.view insertSubview:self.articleView belowSubview:self.pageBarContainerView];
        if (![self shouldPaginate]) {
             self.articleView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
        }
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
        gesture.numberOfTapsRequired = 1;
        [self.articleView addGestureRecognizer:gesture];
        gesture.delegate = self;

        UITapGestureRecognizer *tapLocationGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateTapLocation:)];
        tapLocationGesture.numberOfTapsRequired = 1;
        [self.articleView addGestureRecognizer:tapLocationGesture];
        tapLocationGesture.delegate = self;
        
        _currentPage = 0;
        self.pageNumberLabel.text = @"";
        [self updateBackgrounds];
        [self.titleLabel setText:self.article.title];
        [self.titleLabel2 setText:self.article.title];
        _handlingLink = NO;
        _scrollingInternally = NO;
        _currentHash = nil;

        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        docDir = [docDir URLByAppendingPathComponent:self.article.pmcId isDirectory:YES];
        docDir = [docDir URLByAppendingPathComponent:@"text.html"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:docDir];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [[self articleView] loadRequest:request];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@""];
    [self updateToolbar];
    [self writeCssTemplate];
    currentTapLocation = self.view.center;
    self.titleLabel2.text = @"";
    self.pageNumberLabel.text = @"";
    //bottomBorder = [CALayer layer];
    //bottomBorder.frame = CGRectMake(0.0f, 43.0f, 1024.0f, 1.0f);
    //[self.navigationController.navigationBar.layer addSublayer:bottomBorder];
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
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
        ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
        newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
    } else {
        newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
    }
    self.titleLabel.frame = newRect;
    self.titleLabel2.frame = CGRectOffset(newRect, 0, 20);
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
    self.titleLabel2.frame = CGRectOffset(newRect, 0, 20);
    if ([self shouldPaginate]) {
        if (self.articleView != nil) {
            [self.articleView reload];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.referencePopover dismissPopoverAnimated:NO];
}

#pragma mark - Actions

- (IBAction)doBack:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setValue:@"No" forKey:@"Reading"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doGoBack:(id)sender
{
    if ([[self articleView] canGoBack]) {
        if ([self.articleView.request.URL.scheme isEqualToString:@"file"]) {
            _scrollingInternally = YES;
        }
        [[self articleView] goBack];
    }
}

- (IBAction)doGoForward:(id)sender
{
    if ([[self articleView] canGoForward]) {
        if ([self.articleView.request.URL.scheme isEqualToString:@"file"]) {
            _scrollingInternally = YES;
        }
        [[self articleView] goForward];
    }
}

- (IBAction)doPreferences:(id)sender {
    if (_prefViewController == nil) {
        _prefViewController =  [self.storyboard instantiateViewControllerWithIdentifier:@"preferences"];
        _prefViewController.delegate = self;
        _prefPopoverController = [[UIPopoverController alloc] initWithContentViewController:_prefViewController];
    } 
    
    [_prefPopoverController presentPopoverFromBarButtonItem:self.prefsBarButtonItem permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (IBAction)doInfo:(id)sender {
    if (self.article != nil) {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", @"Copy", nil];
        [menu showFromBarButtonItem:infoBarButtonItem animated:YES];
    }
}

- (IBAction) doNavigation:(id)sender {
    self.articleNavigationController.articleSections = [NSArray arrayWithArray:self.article.articleNavigationItems];
    if (self.article.articleNavigationItems.count > 0) {
        self.articleNavigationPopover.popoverContentSize  = CGSizeMake(290.0f, 44 * self.article.articleNavigationItems.count);
    } else {
        self.articleNavigationPopover.popoverContentSize = CGSizeMake(290.0f, 44);
    }
    WYPopoverBackgroundView* popoverAppearance = [WYPopoverBackgroundView appearance];
    popoverAppearance.fillTopColor = [UIColor popoverButtonColor];
    popoverAppearance.viewContentInsets = UIEdgeInsetsMake(0, 0, 0, 0);

    [self.articleNavigationPopover presentPopoverFromBarButtonItem:self.navBarButtonItem permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (PHArticleNavigationControllerViewController *) articleNavigationController {
    if (!articleNavigationController) {
        articleNavigationController = [[PHArticleNavigationControllerViewController alloc] initWithStyle:UITableViewStylePlain];
        articleNavigationController.delegate = self;
    }
    return articleNavigationController;
}

- (WYPopoverController *) articleNavigationPopover {
    if (!articleNavigationPopover) {
        articleNavigationPopover = [[WYPopoverController alloc] initWithContentViewController:self.articleNavigationController];
    }
    return articleNavigationPopover;
}

- (WYPopoverController *) referencePopover {
    if (!referencePopover) {
        UIViewController *vc = [[UIViewController alloc] init];
        int width = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 370 : 300;
        vc.preferredContentSize = CGSizeMake(width, 500);
        [vc.view addSubview:self.referenceLabel];
        referencePopover = [[WYPopoverController alloc] initWithContentViewController:vc];
    }
    return referencePopover;
}

- (RTLabel *) referenceLabel {
    if (!referenceLabel) {
        int width = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 350 : 280;
        referenceLabel = [[RTLabel alloc] initWithFrame:CGRectMake(0, 0, width, 500)];
        referenceLabel.delegate = self;
    }
    return referenceLabel;
}

- (void)toggleNavBar:(UITapGestureRecognizer *)gesture {
    CGPoint loc = [gesture locationInView:self.articleView];
    [self performSelector:@selector(doToggleNavBar:) withObject:[NSValue valueWithCGPoint:loc] afterDelay:0.4];
}

- (void)doToggleNavBar:(NSValue *)location {
    if (_handlingLink) {
        _handlingLink = NO;
        return;
    }
    _handlingLink = NO;
    double w = self.articleView.frame.size.width;
    CGPoint loc = [location CGPointValue];
    int margin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 150 : 75;
    if ((loc.x > margin) && (loc.x < (w - margin))) {
        if (self.navigationController.navigationBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = NO;
            self.pageNumberBar.hidden = NO;
            self.pageNumberLabel.alpha = 1.0f;
            self.topContainerView.hidden = YES;
            if (![self shouldPaginate]) {
                self.articleView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
                CGPoint offset = self.articleView.scrollView.contentOffset;
                self.articleView.scrollView.contentOffset = CGPointMake(offset.x, offset.y - 64);
            }
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = YES;
            self.pageNumberBar.hidden = YES;
            self.pageNumberLabel.alpha = 0.5f;
            self.topContainerView.hidden = NO;
            self.articleView.scrollView.contentInset = UIEdgeInsetsZero;
        }
    }
    [self setNeedsStatusBarAppearanceUpdate];
    self.articleView.frame = [self articleRect];
}

- (BOOL)prefersStatusBarHidden {
    return self.navigationController.navigationBarHidden;
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
    if ([self shouldPaginate]) {
        int y = 94;
        if (self.navigationController.navigationBarHidden) {
            y = 94;
        }
        return CGRectMake(0, y, [self orientationRect].size.width, [self orientationRect].size.height - 184);
        /*
        if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
            ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
            return CGRectMake(0, y, 1024, 585);
        } else {
            return CGRectMake(0, y, [self orientationRect].size.width, [self orientationRect].size.height - 184);
        }*/
    } else {
        return self.view.frame;
    }
}

- (CGRect)pageNumberBarRect {
    int width =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
    int x = ([self orientationRect].size.width - width) / 2;
    return CGRectMake(x, 20, width, 30);
}

- (void) updateTapLocation:(UIGestureRecognizer *)gestureRecognizer {
    currentTapLocation = [gestureRecognizer locationInView:self.articleView];
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
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        _handlingLink = YES;
    }
    _scrollingInternally = NO;
    if ([self.articleView.request.URL.scheme isEqualToString:@"file"]) {
        NSURL *url = self.articleView.request.URL;
        NSRange range = [url.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
        if (range.location != NSNotFound) {
            NSURL *url2 = request.URL;
            NSRange range = [url2.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
            if (range.location != NSNotFound) {
                _scrollingInternally = YES;
            }
        }
        if ([request.URL.scheme isEqualToString:@"file"]) {
            if ([[request.URL pathExtension] isEqualToString:@"html"]) {
                NSRange range = [request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
                if (range.location == NSNotFound) {
                    PHFigTablePanel *figPanel = [[PHFigTablePanel alloc] initWithFrame:[self orientationRect] URL:request.URL];
                    [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:figPanel];
                    [figPanel showFromPoint:currentTapLocation];
                    return NO;
                }
            }
        }
        if ([request.URL.scheme isEqualToString:@"http"]) {
            NSRange range = [request.URL.absoluteString rangeOfString:@"#"];
            if (range.location != NSNotFound) {
                _scrollingInternally = YES;
                if (self.article.references.count > 0) {
                    __block BOOL refFound = NO;
                    [self.article.references enumerateObjectsUsingBlock:^(PHArticleReference *ref, NSUInteger idx, BOOL *stop) {
                        if ([ref.idAttribute isEqualToString:[request.URL fragment]]) {
                            NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
                            NSURL *url = [NSURL URLWithString:[frag stringByAppendingString:[request.URL fragment]] relativeToURL:self.articleView.request.URL];
                            NSString *labelText = [NSString stringWithFormat:@" [<a href='%@'>Ref List</a>]", [url absoluteString]];
                            labelText = [ref.text stringByAppendingString:labelText];
                            _currentHash = ref.hashAttribute;

                            self.referenceLabel.text = labelText;
                            self.referenceLabel.textColor = [UIColor textColor];
                            self.referenceLabel.backgroundColor = [UIColor popoverButtonColor];
                            CGSize opt = [self.referenceLabel optimumSize];
                            CGRect frame = self.referenceLabel.frame;
                            frame.size.height = (int)opt.height + 5;
                            self.referenceLabel.frame = frame;
                            self.referencePopover.contentViewController.preferredContentSize = CGSizeMake(opt.width + 20, opt.height + 25);

                            WYPopoverBackgroundView *appearance = [WYPopoverBackgroundView appearance];
                            appearance.viewContentInsets = UIEdgeInsetsMake(10, 10, 10, 10);

                            [self.referencePopover presentPopoverFromRect:CGRectMake(currentTapLocation.x, currentTapLocation.y, 1, 1) inView:self.articleView permittedArrowDirections:WYPopoverArrowDirectionAny animated:YES];
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
    if (_newArticle) {
        if (_newArticlePage > -1) {
            [self gotoPage:_newArticlePage animated:NO];
        }
    }
    _newArticle = NO;
    _newArticlePage = -1;
    [UIView animateWithDuration:0.30 animations:^{
        webView.alpha = 1;
    }];
    
    [self updateToolbar];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_scrollingInternally) {
        if ([self shouldPaginate]) {
            int oldPage = _currentPage;
            _currentPage = (int)ceil(((float)scrollView.contentOffset.x / self.articleView.bounds.size.width));
            if (oldPage > _currentPage) {
                _currentPage--;
            }
            [self gotoPage:_currentPage animated:NO];
        }
    }
}

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url {
    [self.referencePopover dismissPopoverAnimated:NO];

    NSRange range = [url.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
    if (range.location != NSNotFound) {
        _scrollingInternally = YES;
    }
    
    NSString *oldURL = self.articleView.request.URL.absoluteString;
    [self.articleView stringByEvaluatingJavaScriptFromString:@"var stateObj = { pmc: 'pmc' };"];
    [self.articleView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.history.pushState(stateObj, 'pmc', %@);", oldURL]];
    [self.articleView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.hash = '%@';", _currentHash]];
    [self.articleView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location = '%@';", url.absoluteString]];
    [self updateToolbar];
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateBackgrounds" object:nil userInfo:nil];
    [self updateBackgrounds];
    [self writeCssTemplate];
    if ([self articleView] != nil) {
        [self.articleView reload];
    } else {
        [self updatePagination];
    }
    self.pageNumberBar.frame = [self pageNumberBarRect];
}

- (void)updateBackgrounds {
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    UIColor *bgColor = [UIColor backgroundColor];
    self.view.backgroundColor = bgColor;
    self.topContainerView.backgroundColor = bgColor;
    self.pageBarContainerView.backgroundColor = bgColor;
    if (self.articleView) {
        self.articleView.backgroundColor = bgColor;
    }
    self.pageNumberBar.nightMode = (backgroundIndex == 2);
    self.titleLabel2.alpha = (backgroundIndex == 2) ? 1.0f : 0.5f;
    self.titleLabel.textColor = [UIColor iconColor];
    self.backBarButtonItem.tintColor = [UIColor iconColor];
    self.goBackBarButtonItem.tintColor = [UIColor iconColor];
    self.forwardBarButtonItem.tintColor = [UIColor iconColor];
    self.refreshBarButtonItem.tintColor = [UIColor iconColor];
    self.stopBarButtonItem.tintColor = [UIColor iconColor];
    self.prefsBarButtonItem.tintColor = [UIColor iconColor];
    self.navBarButtonItem.tintColor = [UIColor iconColor];
    self.infoBarButtonItem.tintColor = [UIColor iconColor];

    WYPopoverBackgroundView* popoverAppearance = [WYPopoverBackgroundView appearance];
    popoverAppearance.fillTopColor = [UIColor popoverButtonColor];
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
    
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:[NSString stringWithFormat:@"#%@", [UIColor backgroundColor].hexStringValue]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:[NSString stringWithFormat:@"#%@", [UIColor textColor].hexStringValue]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:[NSString stringWithFormat:@"#%@", [UIColor linkColor].hexStringValue]];
    
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
    self.pageNumberLabel.text = [NSString stringWithFormat:@"%d of %d",_currentPage + 1, _pageCount];
    [self gotoPage:_currentPage animated:NO];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSURL *url = self.articleView.request.URL;
    NSRange range = [url.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
    if (range.location != NSNotFound) {
        url = self.article.url;
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
    _scrollingInternally = NO;
    _currentPage = page;
    float pageOffset = _currentPage * self.articleView.bounds.size.width;
    [self.articleView.scrollView setContentOffset:CGPointMake(pageOffset, 0.0f) animated:animated];

    self.pageNumberBar.value = _currentPage;
	self.pageNumberLabel.text = [NSString stringWithFormat:@"%d of %d", _currentPage + 1, _pageCount];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:self.article, @"Article", [NSNumber numberWithInt:_currentPage], @"NewPage", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PageChanged" object:self userInfo:infoDict];
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
        NSURL *url = self.articleView.request.URL;
        NSRange range = [url.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
        if (range.location != NSNotFound) {
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
            self.pageNumberBar.hidden = NO;
            self.articleView.frame = [self articleRect];
            self.articleView.scrollView.contentInset = UIEdgeInsetsZero;
            [self updateCSS];
        } else {
            self.pageNumberBar.hidden = YES;
        }
        self.pageBarContainerView.hidden = NO;
        [self.pageBarContainerView addSubview:self.pageNumberBar];
        self.pageNumberBar.frame = [self pageNumberBarRect];
    } else {
        if (self.articleView) {
            self.articleView.scrollView.scrollEnabled = YES;
            self.articleView.scrollView.bounces = YES;
            [self.articleView removeGestureRecognizer:self.pageTapRecognizer];
            [self.articleView removeGestureRecognizer:self.nextPageSwipeRecognizer];
            [self.articleView removeGestureRecognizer:self.previousPageSwipeRecognizer];
            self.articleView.frame = [self articleRect];
            if (!self.navigationController.navigationBarHidden) {
                 self.articleView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
            }
        }
        self.pageBarContainerView.hidden = YES;
        [self.pageNumberBar removeFromSuperview];
    }
}

#pragma mark - Toolbar buttons

- (UILabel *) titleLabel {
    if (!titleLabel) {
        titleLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TITLE_LABEL_WIDTH_PORTRAIT, 44)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:16.0];
        titleLabel.textAlignment = NSTextAlignmentLeft;
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
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home"] style:UIBarButtonItemStylePlain target:self action:@selector(doBack:)];
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)goBackBarButtonItem {
    if (!goBackBarButtonItem) {
        goBackBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoBack:)];
    }
    return goBackBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoForward:)];
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
    }
    return prefsBarButtonItem;
}

- (UIBarButtonItem *)navBarButtonItem {
    if (!navBarButtonItem) {
        navBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contents"] style:UIBarButtonItemStylePlain target:self action:@selector(doNavigation:)];
    }
    return navBarButtonItem;
}

#pragma mark - Toolbar

- (void)updateToolbar {
    self.goBackBarButtonItem.enabled = self.articleView.canGoBack;
    self.forwardBarButtonItem.enabled = self.articleView.canGoForward;
    if ((self.article != nil)) {
        self.infoBarButtonItem.enabled = !self.articleView.isLoading;
        self.prefsBarButtonItem.enabled = !self.articleView.isLoading;
        self.navBarButtonItem.enabled = !self.articleView.isLoading;
    } else {
        self.infoBarButtonItem.enabled = NO;
        self.prefsBarButtonItem.enabled = NO;
        self.navBarButtonItem.enabled = NO;
    }
    
    NSURL *url = self.articleView.request.URL;
    NSString *u = [url absoluteString];
    NSString *v = [NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId];
    
    if ([u rangeOfString:v].location == NSNotFound) {
        self.navBarButtonItem.enabled = NO;
    }
    
    v = [NSString stringWithFormat:@"Documents/%@", self.article.pmcId];
    if ([u rangeOfString:v].location == NSNotFound) {
        self.prefsBarButtonItem.enabled = NO;
    }

    UIBarButtonItem *refreshStopBarButtonItem = self.articleView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    refreshStopBarButtonItem.enabled = (self.article != nil);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem, self.goBackBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem, self.titleBarButtonItem];
        self.navigationItem.rightBarButtonItems = @[self.infoBarButtonItem, self.prefsBarButtonItem, self.navBarButtonItem];
    } else {
        TransparentToolbar *leftTBar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 90, 44)];
        leftTBar.items = @[self.backBarButtonItem, self.goBackBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem];
        TransparentToolbar *rightTBar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 105, 44)];
        rightTBar.items =  @[self.navBarButtonItem, self.prefsBarButtonItem, self.infoBarButtonItem];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftTBar];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightTBar];
    }

}

- (void)articleSectionSelected:(NSUInteger)section {
    [self.articleNavigationPopover dismissPopoverAnimated:YES];
    PHArticleNavigationItem *navItem = (PHArticleNavigationItem *)[self.article.articleNavigationItems objectAtIndex:section];
    NSURL *url = self.articleView.request.URL;
    NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
    [frag appendString:navItem.idAttribute];
    url = [NSURL URLWithString:frag relativeToURL:url];
    NSLog(@"DEBUG - absoluteString: %@", [url absoluteString]);
    [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
}

@end
