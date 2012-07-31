//
//  PHDetailViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PHDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UIWebView *articleView;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

- (IBAction) doGoBack:(id)sender;

@end
