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
#import "TransparentToolbar.h"
#import "PHColors.h"
#import "UIColor+Expanded.h"

#define TITLE_LABEL_WIDTH_LANDSCAPE 680
#define TITLE_LABEL_WIDTH_PORTRAIT 430

@interface PHDetailViewController () {
    PopoverView *popover;
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
@synthesize backBarButtonItem, goBackBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, leftToolbar;
@synthesize infoBarButtonItem, prefsBarButtonItem, navBarButtonItem;
@synthesize articleNavigationController, articleNavigationPopover;
@synthesize pageTapRecognizer, nextPageSwipeRecognizer, previousPageSwipeRecognizer;
@synthesize pageNumberBar;

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
        self.articleView.backgroundColor = [PHColors backgroundColor];
        [self.view insertSubview:self.articleView belowSubview:self.pageBarContainerView];
        
        
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
        self.topContainerView.hidden = !self.navigationController.navigationBarHidden;
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
    self.wantsFullScreenLayout = YES;
    //self.viewDeckController.delegate = self;
    //self.viewDeckController.panningView = self.topContainerView;
    [[self navigationItem] setTitle:@""];
    [self updateToolbar];
    [self writeCssTemplate];
    currentTapLocation = CGPointMake(350, 100);
    self.topContainerView.hidden = YES;
    self.titleLabel2.text = @"";
    self.pageNumberLabel.text = @"";
    self.navigationController.navigationBar.translucent = YES;
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 43.0f, 1024.0f, 1.0f);
    [self.navigationController.navigationBar.layer addSublayer:bottomBorder];
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
    //self.titleLabel2.hidden = !self.navigationController.navigationBarHidden;
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
    CGRect newRect2 = self.titleLabel2.frame;
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
        newRect2.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
    } else {
        newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
        newRect2.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
    }
    self.titleLabel.frame = newRect;
    self.titleLabel2.frame = newRect2;
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

    [self.articleNavigationPopover presentPopoverFromBarButtonItem:self.navBarButtonItem permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
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
    if ((loc.x > 150) && (loc.x < (w - 150))) {
        if (self.navigationController.navigationBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = NO;
            self.pageNumberBar.hidden = NO;
            self.pageNumberLabel.alpha = 1.0f;
            self.topContainerView.hidden = YES;
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            self.navigationController.navigationBarHidden = YES;
            self.pageNumberBar.hidden = YES;
            self.pageNumberLabel.alpha = 0.5f;
            self.topContainerView.hidden = NO;
        }
    }
    [self.articleView setFrame:[self articleRect]];
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
        int y = 30;
        if (self.navigationController.navigationBarHidden) {
            y = 94;
        }
        if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
            ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
            return CGRectMake(0, y, 1024, 585);
        } else {
            return CGRectMake(0, y, 768, 840);
        }
    } else {
        return self.view.frame;
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
                            
                            RTLabel *label = [[RTLabel alloc] initWithFrame:CGRectMake(0, 0, 350, 500)];
                            _currentHash = ref.hashAttribute;
                            label.delegate = self;
                            label.text = labelText;
                            label.textColor = [PHColors textColor];
                            CGSize opt = [label optimumSize];
                            CGRect frame = [label frame];
                            frame.size.height = (int)opt.height+5;
                            [label setFrame:frame];

                            popover = [[PopoverView alloc] initWithFrame:label.frame];
                            int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
                            if (backgroundIndex > 0) {
                                popover.backgroundGradientColors = @[[PHColors popoverButtonColor], [PHColors popoverBackgroundColor]];
                            }
                            [popover showAtPoint:currentTapLocation inView:self.articleView withContentView:label];
                            //popover = [PopoverView showPopoverAtPoint:currentTapLocation inView:self.articleView withContentView:label delegate:self];
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
    //NSLog(@"Offset: %f", scrollView.contentOffset.x);
}

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url {
    if (popover) {
        [popover dismiss:NO];
    }

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
    self.view.backgroundColor = bgColor;
    self.topContainerView.backgroundColor = bgColor;
    self.pageBarContainerView.backgroundColor = bgColor;
    if (self.articleView) {
        self.articleView.backgroundColor = bgColor;
    }
    self.pageNumberBar.nightMode = (backgroundIndex == 2);
    self.titleLabel2.alpha = (backgroundIndex == 2) ? 1.0f : 0.5f;
    self.titleLabel.textColor = [PHColors iconColor];
    
    bottomBorder.backgroundColor = [[PHColors iconColor] CGColor];
    [((UIButton*)self.backBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"home"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.goBackBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"back"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.forwardBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"forward"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.refreshBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"refresh"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.stopBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"stop"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.prefsBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"text"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.navBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"contents"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [((UIButton*)self.infoBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"action"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
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
    
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:[NSString stringWithFormat:@"#%@", [PHColors backgroundColor].hexStringValue]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:[NSString stringWithFormat:@"#%@", [PHColors textColor].hexStringValue]];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:[NSString stringWithFormat:@"#%@", [PHColors linkColor].hexStringValue]];
    
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
    self.topContainerView.hidden = !self.navigationController.navigationBarHidden;
    if ([self shouldPaginate]) {
        if (self.articleView) {
            self.articleView.scrollView.scrollEnabled = NO;
            self.articleView.scrollView.bounces = NO;
            [self.articleView addGestureRecognizer:self.pageTapRecognizer];
            [self.articleView addGestureRecognizer:self.nextPageSwipeRecognizer];
            [self.articleView addGestureRecognizer:self.previousPageSwipeRecognizer];
            self.pageNumberBar.hidden = NO;
            //self.titleLabel2.hidden = NO;
            self.articleView.frame = [self articleRect];
            [self updateCSS];
        } else {
            self.pageNumberBar.hidden = YES;
            //self.titleLabel2.hidden = YES;
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
            [self.articleView setFrame:[self articleRect]];
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
        UIImage *image = [UIImage imageNamed:@"home"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doBack:) forControlEvents:UIControlEventTouchUpInside];
        backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)goBackBarButtonItem {
    if (!goBackBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"back"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doGoBack:) forControlEvents:UIControlEventTouchUpInside];
        goBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return goBackBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!forwardBarButtonItem) {        
        UIImage *image = [UIImage imageNamed:@"forward"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doGoForward:) forControlEvents:UIControlEventTouchUpInside];
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!refreshBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"refresh"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(10.0, 2.0, 10.0, 2.0)];
        [button addTarget:self action:@selector(doReload:) forControlEvents:UIControlEventTouchUpInside];
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!stopBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"stop"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doStop:) forControlEvents:UIControlEventTouchUpInside];
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)infoBarButtonItem {
    if (!infoBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"action"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(10.0, 2.0, 10.0, 2.0)];
        [button addTarget:self action:@selector(doInfo:) forControlEvents:UIControlEventTouchUpInside];
        infoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return infoBarButtonItem;
}

- (UIBarButtonItem *)prefsBarButtonItem {
    if (!prefsBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"text"];
        UIButton *prefButton = [UIButton buttonWithType:UIButtonTypeCustom];
        prefButton.frame = CGRectMake(0, 0, 28 , 42);
        [prefButton setImage:image forState:UIControlStateNormal];;
        [prefButton setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [prefButton addTarget:self action:@selector(doPreferences:) forControlEvents:UIControlEventTouchUpInside];
        prefsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:prefButton];        
    }
    return prefsBarButtonItem;
}

- (UIBarButtonItem *)navBarButtonItem {
    if (!navBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"contents"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doNavigation:) forControlEvents:UIControlEventTouchUpInside];
        navBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return navBarButtonItem;
}

- (UIToolbar *) leftToolbar {
    if (!leftToolbar) {
        leftToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 5.0f;

        NSArray *itemsLeft = [NSArray arrayWithObjects:
                                        self.backBarButtonItem,
                                        fixedSpace,
                                        fixedSpace,
                                        self.goBackBarButtonItem,
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

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.articleView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    refreshStopBarButtonItem.enabled = (self.article != nil);
    
    NSMutableArray *itemsLeft = [self.leftToolbar.items mutableCopy];
    
    [itemsLeft replaceObjectAtIndex:(7) withObject:refreshStopBarButtonItem];

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
    
    TransparentToolbar *toolbarRight = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 135, 44.0f)];
    toolbarRight.items = itemsRight;
    toolbarRight.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarRight];
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
