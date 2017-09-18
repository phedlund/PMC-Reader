//
//  PageNumberBar.h
//  PMC Reader
//
//  Created by Peter Hedlund on 9/17/17.
//  Copyright (c) 2017 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PageNumberBarDelegate;

@interface PageNumberBar: UISlider

@property (nonatomic, weak) id <PageNumberBarDelegate> delegate;

- (void)refresh;

@end

@protocol PageNumberBarDelegate <NSObject>

@required

- (NSString*)pageNumberBar: (PageNumberBar*)pageNumberBar textForValue: (float)value;
- (void)pageNumberBar: (PageNumberBar*)pageNumberBar valueSelected: (float)value;

@end
