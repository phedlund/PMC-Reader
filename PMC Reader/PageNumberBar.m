//
//  PageNumberBar.m
//  PMC Reader
//
//  Created by Peter Hedlund on 9/17/17.
//  Copyright (c) 2017 Peter Hedlund. All rights reserved.
//

#import "PageNumberBar.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+PHColor.h"

#define kDotSpacing 10.0f

@interface PageNumberPopupView: UIView

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSString *text;

@end

@implementation PageNumberPopupView

@synthesize font = _font;
@synthesize text = _text;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:13];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    //Outer border
    [[[UIColor popoverIconColor] colorWithAlphaComponent:0.8] setFill];
    CGRect roundedRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, floorf(self.bounds.size.height * 0.8));
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:6.0];
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    CGFloat midX = CGRectGetMidX(self.bounds);
    CGPoint p0 = CGPointMake(midX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((midX - 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((midX + 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    [roundedRectPath appendPath:arrowPath];
    [roundedRectPath fill];
    
    //Inner
    [[[UIColor popoverBackgroundColor] colorWithAlphaComponent:0.8] setFill];
    CGRect roundedRect2 = CGRectInset(roundedRect, 1.5, 1.5);
    UIBezierPath *roundedRectPath2 = [UIBezierPath bezierPathWithRoundedRect:roundedRect2 cornerRadius:4.0];
    
    UIBezierPath *arrowPath2 = [UIBezierPath bezierPath];
    CGPoint p1 = CGPointMake(midX, CGRectGetMaxY(self.bounds) - 1.5);
    [arrowPath2 moveToPoint:p1];
    [arrowPath2 addLineToPoint:CGPointMake((midX - 8.5), CGRectGetMaxY(roundedRect2))];
    [arrowPath2 addLineToPoint:CGPointMake((midX + 8.5), CGRectGetMaxY(roundedRect2))];
    [arrowPath2 closePath];
    
    [roundedRectPath2 appendPath:arrowPath2];
    [roundedRectPath2 fill];
    
    if (self.text) {
        NSDictionary *fontAttributes = @{NSFontAttributeName:self.font, NSForegroundColorAttributeName:[UIColor popoverIconColor]};
       
        CGSize size = [_text sizeWithAttributes:fontAttributes];
        CGRect textRect = CGRectMake(roundedRect.origin.x  + ((rect.size.width - size.width) / 2.0),
                              roundedRect.origin.y + ((rect.size.height - (roundedRect.size.height  * 0.8)) / 2.0),
                              size.width,
                              size.height);
        
        [_text drawInRect:CGRectOffset(textRect, 0, 0) withAttributes:fontAttributes];
    }
}

- (void)setText:(NSString *)text {
    _text = text;
    [self setNeedsDisplay];
}

@end


@interface PageNumberBar ()

@property (nonatomic, strong) UIImage* dotsImage;
@property (nonatomic, strong) UIImageView* dotsImageView;
@property (nonatomic, strong) UIImage* clearImage;
@property (nonatomic, strong) UIImage* thumbImage;
@property (nonatomic, strong) PageNumberPopupView* pageNumberPopup;

- (CGRect)thumbRect;
- (void)animatePageNumberPopupAlpha:(BOOL)aFadeIn;
- (void)updatePageNumberPopupPosition;
- (void)updatePageNumberPopupValue;

@end

@implementation PageNumberBar

@synthesize dotsImage = _dotsImage;
@synthesize dotsImageView = _dotsImageView;
@synthesize clearImage = _clearImage;
@synthesize thumbImage = _thumbImage;
@synthesize pageNumberPopup = _pageNumberPopup;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setThumbImage: self.thumbImage forState:UIControlStateNormal];
        [self setMaximumTrackImage: self.clearImage forState:UIControlStateNormal];
        [self setMinimumTrackImage: self.clearImage forState:UIControlStateNormal];
        [self addSubview: self.dotsImageView];
        [self addSubview: self.pageNumberPopup];
    }
    return self;
}

- (void)refresh {
    _thumbImage = nil;
    [self setThumbImage:self.thumbImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _dotsImage = nil;
    self.dotsImageView.image = self.dotsImage;
    
    [self updatePageNumberPopupValue];
    [self updatePageNumberPopupPosition];
}


#pragma mark - Private methods

- (CGRect)thumbRect
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds
                                   trackRect:trackRect
                                       value:self.value];
    return thumbR;
}

- (void)animatePageNumberPopupAlpha:(BOOL)show
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         if (show) {
                             self.pageNumberPopup.alpha = 1.0;
                         }
                         else {
                             self.pageNumberPopup.alpha = 0.0;
                         }
                     } completion: nil];
}

- (void)updatePageNumberPopupPosition
{
    CGRect thumbRect = self.thumbRect;
    CGRect popupRect = CGRectOffset(thumbRect, 0, -floorf(thumbRect.size.height * 1.5));
    self.pageNumberPopup.frame = CGRectInset(popupRect, -30, -10);
}

- (void)updatePageNumberPopupValue
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageNumberBar:textForValue:)]) {
        self.pageNumberPopup.text = [self.delegate pageNumberBar:self textForValue:self.value];
    } else {
        self.pageNumberPopup.text = @"";
    }
}


#pragma mark - UIControl touch event tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchPoint = [touch locationInView:self];
    if(CGRectContainsPoint(CGRectInset([self thumbRect], -12.0, -12.0), touchPoint)) {
        [self animatePageNumberPopupAlpha:YES];
        [self updatePageNumberPopupValue];
        [self updatePageNumberPopupPosition];
    }
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self updatePageNumberPopupValue];
    [self updatePageNumberPopupPosition];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self animatePageNumberPopupAlpha:NO];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageNumberBar:valueSelected:)]) {
        [self.delegate pageNumberBar:self valueSelected:self.value];
    }
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark - Internal properties

- (UIImage *)thumbImage {
    
    if (_thumbImage == nil) {
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize size = CGSizeMake(25, 21);
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius: 6].CGPath;
        CGContextAddPath(context, clippath);
        
        CGContextSetFillColorWithColor(context, [UIColor iconColor].CGColor);
        CGContextClosePath(context);
        CGContextFillPath(context);

        clippath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, 2, size.width - 4, size.height- 4) cornerRadius: 4].CGPath;
        CGContextAddPath(context, clippath);
        
        CGContextSetFillColorWithColor(context, [UIColor popoverBackgroundColor].CGColor);
        CGContextClosePath(context);
        CGContextFillPath(context);

        CGContextSetFillColorWithColor(context, [UIColor iconColor].CGColor);
        CGPoint drawPoint = CGPointMake((size.width / 2) - 1.5,  (size.height / 2) - 1.5);
        CGContextFillEllipseInRect(context, CGRectMake(drawPoint.x, drawPoint.y, 3, 3));

        _thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    return _thumbImage;
}

- (UIImage *)dotsImage
{
    if (_dotsImage == nil) {
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width, 3);
        CGFloat oneDotWidth = 3 + kDotSpacing;
        
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor iconColor].CGColor);
    
        NSInteger len = (int)((size.width * scale) / oneDotWidth);
        for (NSInteger i = 0; i < len; i++) {
            CGPoint drawPoint = CGPointMake(i * oneDotWidth + kDotSpacing / 2, 0);
            CGContextFillEllipseInRect(context, CGRectMake(drawPoint.x, drawPoint.y, 3, 3));
        }
        
        _dotsImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _dotsImage;
}

- (UIImageView *)dotsImageView {
    if (_dotsImageView == nil) {
        _dotsImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _dotsImageView.image = self.dotsImage;
        _dotsImageView.contentMode = UIViewContentModeCenter;
        _dotsImageView.clipsToBounds = YES;
        _dotsImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    };
    return _dotsImageView;
}

- (UIImage *)clearImage
{
    if (_clearImage == nil) {
        UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
        _clearImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    };
    return _clearImage;
}

- (PageNumberPopupView *)pageNumberPopup
{
    if (_pageNumberPopup == nil) {
        _pageNumberPopup = [[PageNumberPopupView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 0.0)];
        _pageNumberPopup.backgroundColor = [UIColor clearColor];
        _pageNumberPopup.alpha = 0.0;
    }
    return _pageNumberPopup;
}

@end
