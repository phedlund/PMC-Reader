//
//  PHCollectionViewCell.h
//  PMC Reader
//
//  Created by Peter Hedlund on 4/11/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHCollectionViewCell;

@protocol PHCollectionViewCellDelegate <NSObject>

- (void)collectionViewCellSwiped:(PHCollectionViewCell *)cell;
- (void)buttonTapped:(UIBarButtonItem *)button inCell:(PHCollectionViewCell *)cell;
@optional
- (BOOL)collectionViewCellShouldSwipe:(PHCollectionViewCell *)cell;

@end


@interface PHCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *openGestureRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *closeGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *activityBackground;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *pmcSourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *originalSourceLabel;
@property (strong, nonatomic) IBOutlet UILabel *publishedAsLabel;
@property (strong, nonatomic) IBOutlet UIView *buttonContainerView;
@property (strong, nonatomic) IBOutlet UIView *labelContainerView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *downloadBarButton;
@property (nonatomic, assign) BOOL buttonsVisible;
@property (nonatomic, assign) BOOL activityVisible;

@property (nonatomic, assign) id<PHCollectionViewCellDelegate> delegate;

- (void)showButtons;
- (void)hideButtons;

- (IBAction)doDelete:(UIBarButtonItem *)sender;
- (IBAction)doDownload:(UIBarButtonItem *)sender;

@end
