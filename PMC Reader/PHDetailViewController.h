//
//  PHDetailViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHArticle.h"
#import "PHPrefViewController.h"
#import "PHArticleNavigationController.h"
#import "PHFontsTableController.h"
#import "RTLabel.h"
#import "PageNumberBar.h"

@interface PHDetailViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate, PHPrefViewControllerDelegate, ArticleNavigationDelegate, PHFontsControllerDelegate, RTLabelDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PageNumberBarDelegate>

@property (strong, nonatomic) PHArticle *article;
@property (strong, nonatomic) IBOutlet UIView *pageBarContainerView;
@property (strong, nonatomic) IBOutlet UIView *topContainerView;
@property (strong, nonatomic) UIWebView *articleView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel2;
@property (strong, nonatomic) IBOutlet UILabel *pageNumberLabel;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *titleBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *goBackBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *infoBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *prefsBarButtonItem;
@property (nonatomic, strong, readonly) PageNumberBar *pageNumberBar;

@property (nonatomic, strong, readonly) PHArticleNavigationController *articleNavigationController;
@property (nonatomic, strong, readonly) PHPrefViewController *prefViewController;
@property (nonatomic, strong, readonly) PHFontsTableController *fontsController;
@property (nonatomic, strong, readonly) UIPageViewController *settingsPageController;
@property (nonatomic, strong, readonly) UIPopoverPresentationController *settingsPresentationController;

@property (nonatomic, strong, readonly) RTLabel *referenceLabel;
@property (nonatomic, strong, readonly) UIViewController *referenceController;
@property (nonatomic, strong, readonly) UIPopoverPresentationController *referencePresentationController;


- (void) writeCssTemplate;

- (IBAction) doBack:(id)sender;
- (IBAction) doGoBack:(id)sender;
- (IBAction) doGoForward:(id)sender;
- (IBAction) doReload:(id)sender;
- (IBAction) doStop:(id)sender;
- (IBAction) doPreferences:(id)sender;
- (IBAction) doInfo:(id)sender;

@end
