//
//  PHFigTablePanel.m
//  PMC Reader
//
//  Created by Peter Hedlund on 9/28/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "PHFigTablePanel.h"
#import "UIColor+PHColor.h"

@implementation PHFigTablePanel

- (id)initWithFrame:(CGRect)frame URL:(NSURL *)url
{
    self = [super initWithFrame:frame];
    if (self) {
		self.margin = UIEdgeInsetsMake(40, 20, 20, 20);
        self.padding = UIEdgeInsetsMake(5, 5, 5, 5);
        self.contentColor = [UIColor backgroundColor];
        self.borderColor = [UIColor iconColor];
        self.shouldBounce = NO;
		UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.delegate = self;
        webView.scrollView.bounces = NO;
		[webView loadRequest:[NSURLRequest requestWithURL:url]];
		view = webView;
		[self.contentView addSubview:view];

    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	[view setFrame:self.contentView.bounds];
}

@end
