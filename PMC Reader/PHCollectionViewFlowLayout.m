//
//  PHCollectionViewFlowLayout.m
//  PMC Reader
//
//  Created by Peter Hedlund on 4/11/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//
//  http://stackoverflow.com/questions/13017257/how-do-you-determine-spacing-between-cells-in-uicollectionview-flowlayout/13258495#13258495

#import "PHCollectionViewFlowLayout.h"

@implementation PHCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* arr = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes* atts in arr) {
        if (nil == atts.representedElementKind) {
            NSIndexPath* ip = atts.indexPath;
            atts.frame = [self layoutAttributesForItemAtIndexPath:ip].frame;
        }
    }
    return arr;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes* atts =
    [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (indexPath.item == 0) // degenerate case 1, first item of section
        return atts;
    
    NSIndexPath* ipPrev =
    [NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section];
    
    CGRect fPrev = [self layoutAttributesForItemAtIndexPath:ipPrev].frame;
    CGFloat rightPrev = fPrev.origin.x + fPrev.size.width + 10;
    if (atts.frame.origin.x <= rightPrev) // degenerate case 2, first item of line
        return atts;
    
    CGRect f = atts.frame;
    f.origin.x = rightPrev;
    atts.frame = f;
    return atts;
}

@end
