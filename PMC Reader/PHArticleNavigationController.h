//
//  PHArticleNavigationControllerViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 2/5/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ArticleNavigationDelegate
- (void)articleSectionSelected:(NSUInteger)section;
//- (NSUInteger)selectedMode;
@end

@interface PHArticleNavigationController : UITableViewController {
    id<ArticleNavigationDelegate> __unsafe_unretained _delegate;
}

@property (nonatomic, strong) NSArray *articleSections;
@property (nonatomic, unsafe_unretained) id<ArticleNavigationDelegate> delegate;

@end
