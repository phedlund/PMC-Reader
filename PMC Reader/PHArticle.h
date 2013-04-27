//
//  PHArticle.h
//  PMC Reader
//
//  Created by Peter Hedlund on 11/30/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PHArticle : NSObject <NSCoding> {
    NSURL *url;
    NSString *pmcId;
    NSString *title;
	NSString *authors;
    NSString *source;
    NSArray *articleNavigationItems;
    NSArray *references;
	NSString *error;
    BOOL downloading;
    NSNumber *currentPage;
}

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *pmcId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *authors;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSArray *articleNavigationItems;
@property (nonatomic, copy) NSArray *references;
@property (nonatomic, copy) NSString *error;
@property (nonatomic) BOOL downloading;
@property (nonatomic, copy) NSNumber *currentPage;

@end
