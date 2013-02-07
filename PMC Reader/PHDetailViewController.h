//
//  PHDetailViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHPrefViewController.h"
#import "PHArticleNavigationControllerViewController.h"
#import "IIViewDeckController.h"

@interface PHDetailViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate, PHPrefViewControllerDelegate, ArticleNavigationDelegate, IIViewDeckControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) UIWebView *articleView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIBarButtonItem *titleBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *infoBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *prefsBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *navBarButtonItem;
@property (nonatomic, strong, readonly) UIToolbar *leftToolbar;

@property (strong, nonatomic) PHArticleNavigationControllerViewController *articleNavigationController;
@property (strong, nonatomic) UIPopoverController *articleNavigationPopover;

- (void) writeCssTemplate;

- (IBAction) doGoBack:(id)sender;
- (IBAction) doGoForward:(id)sender;
- (IBAction) doReload:(id)sender;
- (IBAction) doStop:(id)sender;
- (IBAction) doPreferences:(id)sender;
- (IBAction) doInfo:(id)sender;
- (IBAction) doNavigation:(id)sender;

@end
