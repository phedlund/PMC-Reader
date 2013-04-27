//
//  PHArticle.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/30/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHArticle.h"

@implementation PHArticle

@synthesize url;
@synthesize pmcId;
@synthesize title;
@synthesize authors;
@synthesize source;
@synthesize articleNavigationItems;
@synthesize references;
@synthesize error;
@synthesize downloading;
@synthesize currentPage;

- (id) init {
	if (self = [super init]) {
        NSArray *theNavItems = [[NSArray alloc] init];
        self.articleNavigationItems = theNavItems;
        NSArray *theReferences = [[NSArray alloc] init];
        self.references = theReferences;
    }
	return self;
}

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
        url = [decoder decodeObjectForKey:@"url"];
        pmcId = [decoder decodeObjectForKey:@"pmcid"];
        title = [decoder decodeObjectForKey:@"title"];
        authors = [decoder decodeObjectForKey:@"authors"];
        source = [decoder decodeObjectForKey:@"source"];
        articleNavigationItems = [decoder decodeObjectForKey:@"articlenavigationitems"];
        references = [decoder decodeObjectForKey:@"references"];
        error = [decoder decodeObjectForKey:@"error"];
        downloading = [decoder decodeBoolForKey:@"downloading"];
        currentPage = [decoder decodeObjectForKey:@"currentpage"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:url forKey:@"url"];
    [encoder encodeObject:pmcId forKey:@"pmcid"];
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeObject:authors forKey:@"authors"];
    [encoder encodeObject:source forKey:@"source"];
    [encoder encodeObject:articleNavigationItems forKey:@"articlenavigationitems"];
    [encoder encodeObject:references forKey:@"references"];
    [encoder encodeObject:error forKey:@"error"];
    [encoder encodeBool:downloading forKey:@"downloading"];
    [encoder encodeObject:currentPage forKey:@"currentpage"];
}

@end
