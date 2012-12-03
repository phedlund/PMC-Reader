//
//  PHSearchTableViewCell.h
//  PMC Reader
//
//  Created by Peter Hedlund on 11/20/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PHSearchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *pmcSourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *originalSourceLabel;

@end
