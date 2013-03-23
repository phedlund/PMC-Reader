//
//  PHArticleReference.h
//  PMC Reader
//
//  Created by Peter Hedlund on 3/20/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PHArticleReference : NSObject <NSCoding> {
    NSString *text;
	NSString *idAttribute;
}

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *idAttribute;

@end
