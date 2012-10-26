//
//  PHDetailViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHPrefViewController.h"

@interface PHDetailViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate, PHPrefViewControllerDelegate>

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
@property (nonatomic, strong, readonly) UIToolbar *leftToolbar;

- (void) writeCssTemplate;

- (IBAction) doGoBack:(id)sender;
- (IBAction) doGoForward:(id)sender;
- (IBAction) doReload:(id)sender;
- (IBAction) doStop:(id)sender;
- (IBAction) doPreferences:(id)sender;
- (IBAction) doInfo:(id)sender;

@end
