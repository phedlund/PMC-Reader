//
//  NSMutableArray+Extra.m
//  PMC Reader
//
//  Created by Peter Hedlund on 12/1/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "NSMutableArray+Extra.h"

@implementation NSMutableArray (Extra)

- (BOOL)writeToPlistFile:(NSString*)fileName{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *saveUrl = [paths objectAtIndex:0];
    saveUrl = [saveUrl URLByAppendingPathComponent:fileName isDirectory:NO];
    saveUrl = [saveUrl URLByAppendingPathExtension:@"plist"];
    BOOL didWriteSuccessfull = [NSKeyedArchiver archiveRootObject:self toFile:[saveUrl path]];
    return didWriteSuccessfull;
}

+ (NSMutableArray*)readFromPlistFile:(NSString*)fileName{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *openUrl = [paths objectAtIndex:0];
    openUrl = [openUrl URLByAppendingPathComponent:fileName isDirectory:NO];
    openUrl = [openUrl URLByAppendingPathExtension:@"plist"];
    return  [NSKeyedUnarchiver unarchiveObjectWithFile:[openUrl path]];
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
