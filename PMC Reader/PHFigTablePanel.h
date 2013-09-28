//
//  PHFigTablePanel.h
//  PMC Reader
//
//  Created by Peter Hedlund on 9/28/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "UAModalPanel.h"

@interface PHFigTablePanel : UAModalPanel <UIWebViewDelegate> {
    UIView *view;
}

- (id)initWithFrame:(CGRect)frame URL:(NSURL *)url;


@end
