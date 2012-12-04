//
//  NSMutableArray+PList.m
//  PMC Reader
//
//  Created by Peter Hedlund on 12/1/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "NSMutableArray+PList.h"

@implementation NSMutableArray (PList)

- (BOOL)writeToPlistFile:(NSString*)fileName{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
    BOOL didWriteSuccessfull = [data writeToFile:path atomically:YES];
    return didWriteSuccessfull;
}

+ (NSMutableArray*)readFromPlistFile:(NSString*)filename{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSData * data = [NSData dataWithContentsOfFile:path];
    return  [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self objectAtIndex:from];
        [self removeObjectAtIndex:from];
        if (to >= [self count]) {
            [self addObject:obj];
        } else {
            [self insertObject:obj atIndex:to];
        }
    }
}

@end
