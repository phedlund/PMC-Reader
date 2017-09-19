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
#import "UIColor+Hex.h"
#import "PHFigTablePanel.h"
#import "TUSafariActivity.h"

#define TITLE_LABEL_WIDTH_LANDSCAPE 670
#define TITLE_LABEL_WIDTH_PORTRAIT 420

@interface PHDetailViewController () {
    CGPoint currentTapLocation;
    NSInteger _pageCount;
    NSInteger _currentPage;
    double _currentWidth;
    double _currentWidthLandscape;
    BOOL _handlingLink;
    BOOL _scrollingInternally;
    NSString *_currentHash;
    CALayer *bottomBorder;
    BOOL _newArticle;
    NSInteger _newArticlePage;
    NSArray *_settingsControllers;
    UIPopoverPresentationController *_activityPopover;
}

@property (nonatomic, strong, readonly) UITapGestureRecognizer *pageTapRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *nextPageSwipeRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *previousPageSwipeRecognizer;

- (void) configureView;
- (void) updatePagination;
- (BOOL) shouldPaginate;
- (void) gotoPage:(NSInteger)page animated:(BOOL)animated;
- (void) updateBackgrounds;

@end

@implementation PHDetailViewController

@synthesize article = _article;
@synthesize articleView = _articleView;
@synthesize articleNavigationController;
@synthesize prefViewController;
@synthesize fontsController;
@synthesize settingsPageController;
@synthesize settingsPresentationController;
@synthesize titleLabel, titleBarButtonItem;
@synthesize backBarButtonItem, goBackBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem;
@synthesize infoBarButtonItem, prefsBarButtonItem;
@synthesize pageTapRecognizer, nextPageSwipeRecognizer, previousPageSwipeRecognizer;
@synthesize pageNumberBar = _pageNumberBar;
@synthesize referenceLabel;
@synthesize referenceController;
@synthesize referencePresentationController;

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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect newRect = self.titleLabel.frame;
        if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
            ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
            newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
        } else {
            newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
        }
        self.titleLabel.frame = newRect;
        self.titleLabel2.frame = CGRectOffset(newRect, 0, 20);
    } else {
        self.titleLabel2.frame = CGRectMake(20, 10, [self orientationRect].size.width - 40, 21);
        self.titleLabel2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    }
    self.titleLabel2.hidden = !self.navigationController.navigationBarHidden;
    self.pageNumberBar.frame = [self pageNumberBarRect];
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect newRect = self.titleLabel.frame;
        if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            newRect.size.width = TITLE_LABEL_WIDTH_LANDSCAPE;
        } else {
            newRect.size.width = TITLE_LABEL_WIDTH_PORTRAIT;
        }
        self.titleLabel.frame = newRect;
        self.titleLabel2.frame = CGRectOffset(newRect, 0, 20);
     }

    if ([self shouldPaginate]) {
        if (self.articleView != nil) {
            [self.articleView reload];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //
    } else {
        self.titleLabel2.frame = CGRectMake(20, 10, [self orientationRect].size.width - 40, 21);
        self.titleLabel2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    }
    self.pageNumberBar.frame = [self pageNumberBarRect];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)prefersStatusBarHidden {
    return self.navigationController.navigationBar.hidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(nonnull UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
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

- (UIPageViewController *) settingsPageController {
    if (!settingsPageController) {
        settingsPageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        settingsPageController.dataSource = self;
        settingsPageController.delegate = self;
        [settingsPageController setViewControllers:@[self.articleNavigationController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            settingsPageController.preferredContentSize = CGSizeMake(240, 362);
        } else {
            settingsPageController.preferredContentSize = CGSizeMake(220, 344);
        }
        settingsPageController.modalPresentationStyle = UIModalPresentationPopover;
    }
    return settingsPageController;
}

- (IBAction)doPreferences:(id)sender {
    settingsPresentationController = self.settingsPageController.popoverPresentationController;
    settingsPresentationController.delegate = self;
    settingsPresentationController.barButtonItem = self.prefsBarButtonItem;
    settingsPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    settingsPresentationController.backgroundColor = [UIColor popoverBackgroundColor];

    self.articleNavigationController.articleSections = [NSArray arrayWithArray:self.article.articleNavigationItems];;
    if (!_settingsControllers) {
        _settingsControllers = @[self.articleNavigationController, self.prefViewController, self.fontsController];
    }
    [self presentViewController:self.settingsPageController animated:YES completion:nil];
}

- (IBAction)doInfo:(id)sender {
    if (self.article != nil) {
        NSURL *url = self.articleView.request.URL;
        NSRange range = [url.absoluteString rangeOfString:[NSString stringWithFormat:@"Documents/%@/text.html", self.article.pmcId]];
        if (range.location != NSNotFound) {
            url = self.article.url;
        }

        TUSafariActivity *sa = [[TUSafariActivity alloc] init];

        NSArray *activityItems = @[url];
        NSArray *activities = @[sa];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _activityPopover = activityViewController.popoverPresentationController;
            _activityPopover.delegate = self;
            _activityPopover.barButtonItem = self.infoBarButtonItem;
            _activityPopover.permittedArrowDirections = UIPopoverArrowDirectionAny;
            [self presentViewController:activityViewController animated:YES completion:nil];
        } else {
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
    }
}

- (PHArticleNavigationController *) articleNavigationController {
    if (!articleNavigationController) {
        articleNavigationController = [[PHArticleNavigationController alloc] initWithStyle:UITableViewStylePlain];
        articleNavigationController.delegate = self;
    }
    return articleNavigationController;
}

- (PHPrefViewController *) prefViewController {
    if (!prefViewController) {
        prefViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"preferences"];
        prefViewController.delegate = self;
    }
    return prefViewController;
}

- (PHFontsTableController *) fontsController {
    if (!fontsController) {
        fontsController = [[PHFontsTableController alloc] initWithStyle:UITableViewStylePlain];
        fontsController.delegate = self;
    }
    return fontsController;
}

- (UIViewController *)referenceController {
    if (!referenceController) {
        referenceController = [UIViewController new];
        referenceController.view = self.referenceLabel;
        referenceController.modalPresentationStyle = UIModalPresentationPopover;
    }
    return referenceController;
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
            self.navigationController.navigationBarHidden = YES;
            self.pageNumberBar.hidden = YES;
            self.pageNumberLabel.alpha = 0.5f;
            self.topContainerView.hidden = NO;
            self.titleLabel2.hidden = NO;
            self.articleView.scrollView.contentInset = UIEdgeInsetsZero;
        }
    }
    [self setNeedsStatusBarAppearanceUpdate];
    self.articleView.frame = [self articleRect];
}

- (CGRect)orientationRect {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    return CGRectMake(0.0, 0.0, screen.width, screen.height);
}

- (CGRect)articleRect {
    if ([self shouldPaginate]) {
        int topY = self.topContainerView.frame.size.height + ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 30 : 5);
        int bottomY = self.pageBarContainerView.frame.size.height;
        return CGRectMake(0, topY, [self orientationRect].size.width, [self orientationRect].size.height - (topY + bottomY));
    } else {
        return self.view.frame;
    }
}

- (CGRect)pageNumberBarRect {
    NSInteger width = (NSInteger)_currentWidthLandscape;
    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        width = _currentWidth;
    }
    int x = ([self orientationRect].size.width - width) / 2;
    int y = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 20 : 0;
    return CGRectMake(x, y, width, 23);
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
        if ([request.URL.scheme hasPrefix:@"http"]) {
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
                            self.referenceLabel.bounds = CGRectInset(frame, -10, -10);
                            self.referenceController.preferredContentSize = CGSizeMake(opt.width + 20, opt.height + 25);
                            referencePresentationController = self.referenceController.popoverPresentationController;
                            referencePresentationController.backgroundColor = [UIColor popoverButtonColor];
                            referencePresentationController.delegate = self;
                            referencePresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                            referencePresentationController.sourceRect = CGRectMake(currentTapLocation.x, currentTapLocation.y, 1, 1);
                            referencePresentationController.sourceView = webView;
                            [self presentViewController:self.referenceController animated:YES completion:^{
                                //
                            }];
                            
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
            NSInteger oldPage = _currentPage;
            _currentPage = (int)ceil(((float)scrollView.contentOffset.x / self.articleView.bounds.size.width));
            if (oldPage > _currentPage) {
                _currentPage--;
            }
            [self gotoPage:_currentPage animated:NO];
        }
    }
}

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url {
    [self dismissViewControllerAnimated:YES completion:nil];

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
    [self.pageNumberBar refresh];
}

- (void)updateBackgrounds {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    UIColor *bgColor = [UIColor backgroundColor];
    self.view.backgroundColor = bgColor;
    self.topContainerView.backgroundColor = bgColor;
    self.pageBarContainerView.backgroundColor = bgColor;
    if (self.articleView) {
        self.articleView.backgroundColor = bgColor;
    }

    self.titleLabel2.alpha = (backgroundIndex == 2) ? 1.0f : 0.5f;
    self.titleLabel.textColor = [UIColor iconColor];
    self.backBarButtonItem.tintColor = [UIColor iconColor];
    self.goBackBarButtonItem.tintColor = [UIColor iconColor];
    self.forwardBarButtonItem.tintColor = [UIColor iconColor];
    self.refreshBarButtonItem.tintColor = [UIColor iconColor];
    self.stopBarButtonItem.tintColor = [UIColor iconColor];
    self.prefsBarButtonItem.tintColor = [UIColor iconColor];
    self.infoBarButtonItem.tintColor = [UIColor iconColor];
    self.settingsPresentationController.backgroundColor = [UIColor popoverBackgroundColor];
    NSArray *subviews = self.settingsPageController.view.subviews;
    UIPageControl *pageControl = nil;
    for (int i=0; i<[subviews count]; i++) {
        if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
            pageControl = (UIPageControl *)[subviews objectAtIndex:i];
            pageControl.pageIndicatorTintColor = [UIColor popoverBorderColor];
            pageControl.currentPageIndicatorTintColor = [UIColor iconColor];
            pageControl.backgroundColor = [UIColor popoverButtonColor];
        }
    }
}

- (void) writeCssTemplate
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"pmc_template" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    NSString *font = [[NSUserDefaults standardUserDefaults] objectForKey:@"Font"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONT$" withString:font];

    NSInteger fontSize =[[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONTSIZE$" withString:[NSString stringWithFormat:@"%ldpx", (long)fontSize]];
    
    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
    _currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%ldpx", (long)_currentWidth]];
    
    NSInteger marginLandscape = [[NSUserDefaults standardUserDefaults] integerForKey:@"MarginLandscape"];
    _currentWidthLandscape = (screenSize.height / [UIScreen mainScreen].scale) * ((double)marginLandscape / 100);
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN_LANDSCAPE$" withString:[NSString stringWithFormat:@"%ldpx", (long)_currentWidthLandscape]];

    double lineHeight =[[NSUserDefaults standardUserDefaults] doubleForKey:@"LineHeight"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%fem", lineHeight]];
    
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:[UIColor backgroundColor].cssString];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:[UIColor textColor].cssString];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:[UIColor linkColor].cssString];
    
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
    NSInteger oldPageCount = _pageCount;
    _pageCount = (int)((float)totalWidth/self.articleView.bounds.size.width);
    float ratio = (float)_pageCount/(float)oldPageCount;
    _currentPage = (int)(_currentPage * ratio);
    _currentPage = MAX(_currentPage, 0);
    self.pageNumberBar.maximumValue = _pageCount - 1;
    self.pageNumberLabel.text = [NSString stringWithFormat:@"%ld of %ld", (long)_currentPage + 1, (long)_pageCount];
    [self gotoPage:_currentPage animated:NO];
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
        NSInteger width = (NSInteger)_currentWidthLandscape;
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            width = _currentWidth;
        }
        double viewWidth = self.articleView.frame.size.width;
        int margin = (viewWidth - width) / 2;
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

- (void) gotoPage:(NSInteger)page animated:(BOOL)animated {
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
	self.pageNumberLabel.text = [NSString stringWithFormat:@"%ld of %ld", (long)_currentPage + 1, (long)_pageCount];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:self.article, @"Article", [NSNumber numberWithInteger:_currentPage], @"NewPage", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PageChanged" object:self userInfo:infoDict];
}

- (PageNumberBar *)pageNumberBar
{
    if (_pageNumberBar == nil) {
        _pageNumberBar = [[PageNumberBar alloc] initWithFrame:[self pageNumberBarRect]];
        _pageNumberBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _pageNumberBar.minimumValue = 0;
        _pageNumberBar.maximumValue = 100;
        _pageNumberBar.delegate = self;
    };
    return _pageNumberBar;
}

- (NSString *)pageNumberBar: (PageNumberBar*)pageNumberBar textForValue: (float)value {
    NSInteger current = (NSInteger)value + 1;
    return [NSString stringWithFormat:@"Page %ld", (long)current];
}

- (void)pageNumberBar: (PageNumberBar*)pageNumberBar valueSelected: (float)value {
    [self gotoPage:(NSInteger)value animated:NO];
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
            self.pageNumberBar.hidden = self.navigationController.navigationBarHidden;
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
        prefsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(doPreferences:)];
    }
    return prefsBarButtonItem;
}

#pragma mark - Toolbar

- (void)updateToolbar {
    self.goBackBarButtonItem.enabled = self.articleView.canGoBack;
    self.forwardBarButtonItem.enabled = self.articleView.canGoForward;
    if ((self.article != nil)) {
        self.infoBarButtonItem.enabled = !self.articleView.isLoading;
        self.prefsBarButtonItem.enabled = !self.articleView.isLoading;
    } else {
        self.infoBarButtonItem.enabled = NO;
        self.prefsBarButtonItem.enabled = NO;
    }
    
    NSURL *url = self.articleView.request.URL;
    NSString *u = [url absoluteString];
    NSString *v = [NSString stringWithFormat:@"Documents/%@", self.article.pmcId];
    
    if ([u rangeOfString:v].location == NSNotFound) {
        self.prefsBarButtonItem.enabled = NO;
    }

    UIBarButtonItem *refreshStopBarButtonItem = self.articleView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    refreshStopBarButtonItem.enabled = (self.article != nil);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem, self.goBackBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem, self.titleBarButtonItem];
        self.navigationItem.rightBarButtonItems = @[self.infoBarButtonItem, self.prefsBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem, self.goBackBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem];
        self.navigationItem.rightBarButtonItems = @[self.infoBarButtonItem, self.prefsBarButtonItem];
    }
}

- (void)articleSectionSelected:(NSUInteger)section {
    [self dismissViewControllerAnimated:YES completion:nil];
    PHArticleNavigationItem *navItem = (PHArticleNavigationItem *)[self.article.articleNavigationItems objectAtIndex:section];
    NSURL *url = self.articleView.request.URL;
    NSMutableString* frag = [[NSMutableString alloc] initWithString:@"#"];
    [frag appendString:navItem.idAttribute];
    url = [NSURL URLWithString:frag relativeToURL:url];
    NSLog(@"DEBUG - absoluteString: %@", [url absoluteString]);
    [[self articleView] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)fontSelected:(NSUInteger)font {
    [self settingsChanged:@"Font" newValue:font];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger ind = [_settingsControllers indexOfObject:viewController];
    UIViewController *nextController;
    if (ind < (_settingsControllers.count - 1)) {
        nextController = [_settingsControllers objectAtIndex:ind + 1];
    }
    return nextController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger ind = [_settingsControllers indexOfObject:viewController];
    UIViewController *nextController;
    if (ind > 0) {
        nextController = [_settingsControllers objectAtIndex:ind - 1];
    }
    return nextController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return 3;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

@end
