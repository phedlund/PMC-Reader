//
//  PHArticleNavigationItem.m
//  PMC Reader
//
//  Created by Peter Hedlund on 2/4/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHArticleNavigationItem.h"

@implementation PHArticleNavigationItem

@synthesize title;
@synthesize idAttribute;

- (id) init {
	if (self = [super init]) {
        //
    }
	return self;
}

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
        title = [decoder decodeObjectForKey:@"title"];
        idAttribute = [decoder decodeObjectForKey:@"idattribute"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeObject:idAttribute forKey:@"idattribute"];
}

@end
