//
//  PHDetailViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHPrefViewController.h"

@interface PHDetailViewController : UIViewController <UISplitViewControllerDelegate, UIActionSheetDelegate, UIWebViewDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate, PHPrefViewControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) UIWebView *articleView;

- (void) writeCssTemplate;

- (IBAction) doGoBack:(id)sender;
- (IBAction) doGoForward:(id)sender;
- (IBAction) doPreferences:(id)sender;
- (IBAction) doInfo:(id)sender;

@end
