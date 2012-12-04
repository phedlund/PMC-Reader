//
//  NSMutableArray+PList.h
//  PMC Reader
//
//  Created by Peter Hedlund on 12/1/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (PList)

-(BOOL)writeToPlistFile:(NSString*)fileName;
+(NSMutableArray*)readFromPlistFile:(NSString*)fileName;

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

@end
