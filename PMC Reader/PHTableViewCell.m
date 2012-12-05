//
//  PHSearchTableViewCell.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/20/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHTableViewCell.h"

@implementation PHTableViewCell

@synthesize activityIndicator;

- (UIActivityIndicatorView *)activityIndicator {
    
    if (!activityIndicator) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return activityIndicator;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
