//
//  PHArticleReference.m
//  PMC Reader
//
//  Created by Peter Hedlund on 3/20/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHArticleReference.h"

@implementation PHArticleReference

@synthesize text;
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
        text = [decoder decodeObjectForKey:@"text"];
        idAttribute = [decoder decodeObjectForKey:@"idattribute"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:text forKey:@"text"];
    [encoder encodeObject:idAttribute forKey:@"idattribute"];
}

@end
