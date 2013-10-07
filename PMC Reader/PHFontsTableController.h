//
//  PHFontsTableControllerViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 10/5/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PHFontsControllerDelegate
- (void)fontSelected:(NSUInteger)font;
@end

@interface PHFontsTableController : UITableViewController {
    id<PHFontsControllerDelegate> __unsafe_unretained _delegate;
}

@property (strong, nonatomic) NSArray *fonts;
@property (nonatomic, unsafe_unretained) id<PHFontsControllerDelegate> delegate;

@end
