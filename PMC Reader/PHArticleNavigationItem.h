//
//  PHArticleNavigationItem.h
//  PMC Reader
//
//  Created by Peter Hedlund on 2/4/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PHArticleNavigationItem : NSObject <NSCoding> {
    NSString *title;
	NSString *idAttribute;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *idAttribute;

@end
