//
//  CRToastView.m
//  CRToastDemo
//
//  Created by Daniel on 12/19/14.
//  Copyright (c) 2014 Collin Ruffenach. All rights reserved.
//

#import "CRToastView.h"
#import "CRToast.h"
#import "CRToastLayoutHelpers.h"

@interface CRToastView ()
@end

static CGFloat const kCRStatusBarViewNoImageLeftContentInset = 10;
static CGFloat const kCRStatusBarViewNoImageRightContentInset = 10;
NSString *const ToastDidTouchCloseButtonNotification = @"kDidTouchToastCloseButtonNotification";
// UIApplication's statusBarFrame will return a height for the status bar that includes
// a 5 pixel vertical padding. This frame height is inappropriate to use when centering content
// vertically under the status bar. This adjustment is uesd to correct the frame height when centering
// content under the status bar.

static CGFloat const CRStatusBarViewUnderStatusBarYOffsetAdjustment = -5;

static CGFloat CRImageViewFrameXOffsetForAlignment(CRToastAccessoryViewAlignment alignment, CGSize contentSize) {
    CGFloat imageSize = contentSize.height;
    CGFloat xOffset = 0;

    if (alignment == CRToastAccessoryViewAlignmentLeft) {
        xOffset = 5;
    } else if (alignment == CRToastAccessoryViewAlignmentCenter) {
        // Calculate mid point of contentSize, then offset for x for full image width
        // that way center of image will be center of content view
        xOffset = (contentSize.width / 2) - (imageSize / 2);
    } else if (alignment == CRToastAccessoryViewAlignmentRight) {
        xOffset = contentSize.width - imageSize;
    }

    return xOffset;
}

static CGFloat CRContentXOffsetForViewAlignmentAndWidth(CRToastAccessoryViewAlignment alignment, CGFloat width) {
    return (width == 0 || alignment != CRToastAccessoryViewAlignmentLeft) ?
    kCRStatusBarViewNoImageLeftContentInset :
    width + kCRStatusBarViewNoImageLeftContentInset;
}

static CGFloat CRToastWidthOfViewWithAlignment(CGFloat height, BOOL showing, CRToastAccessoryViewAlignment alignment) {
    return (!showing || alignment == CRToastAccessoryViewAlignmentCenter) ?
    0 :
    height;
}

CGFloat CRContentWidthForAccessoryViewsWithAlignments(CGFloat fullContentWidth, CGFloat fullContentHeight, BOOL showingImage, CRToastAccessoryViewAlignment imageAlignment, BOOL showingActivityIndicator, CRToastAccessoryViewAlignment activityIndicatorAlignment) {
    CGFloat width = fullContentWidth;

    width -= CRToastWidthOfViewWithAlignment(fullContentHeight, showingImage, imageAlignment);
    width -= CRToastWidthOfViewWithAlignment(fullContentHeight, showingActivityIndicator, activityIndicatorAlignment);

    if (imageAlignment == activityIndicatorAlignment && showingActivityIndicator && showingImage) {
        width += fullContentWidth;
    }

    if (!showingImage && !showingActivityIndicator) {
        width -= (kCRStatusBarViewNoImageLeftContentInset + kCRStatusBarViewNoImageRightContentInset);
    }

    return width;
}

static CGFloat CRCenterXForActivityIndicatorWithAlignment(CRToastAccessoryViewAlignment alignment, CGFloat viewWidth, CGFloat contentWidth) {
    CGFloat center = 0;
    CGFloat offset = viewWidth / 2;

    switch (alignment) {
        case CRToastAccessoryViewAlignmentLeft:
            center = offset; break;
        case CRToastAccessoryViewAlignmentCenter:
            center = (contentWidth / 2) - offset; break;
        case CRToastAccessoryViewAlignmentRight:
            center = contentWidth - offset; break;
    }

    return center;
}

@implementation CRToastView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.accessibilityLabel = NSStringFromClass([self class]);
        //self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.userInteractionEnabled = NO;
        imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
        self.imageView = imageView;

        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.userInteractionEnabled = NO;
        [self addSubview:activityIndicator];
        self.activityIndicator = activityIndicator;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.userInteractionEnabled = NO;
        [self addSubview:label];
        self.label = label;
        
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.userInteractionEnabled = NO;
        [self addSubview:subtitleLabel];
        self.subtitleLabel = subtitleLabel;
        
        self.isAccessibilityElement = YES;

        UIButton *closeButton = [[UIButton alloc] initWithFrame:(CGRectZero)];
        
        [closeButton setImage:[UIImage imageNamed:@"btnClose"] forState:UIControlStateNormal];
        [self addSubview:closeButton];
        self.closeButton = closeButton;
        [self.closeButton addTarget:self action:@selector(didTouchCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)didTouchCloseButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ToastDidTouchCloseButtonNotification object:sender];
}


-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}


-(void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIInterfaceOrientation orientation = CRGetDeviceOrientation();
    
    CGRect contentFrame = self.bounds;
    CGSize imageSize = self.imageView.image.size;

    CGFloat statusBarYOffset = self.toast.displayUnderStatusBar ? (CRGetStatusBarHeight()+CRStatusBarViewUnderStatusBarYOffsetAdjustment) : 0;
    contentFrame.size.height = CGRectGetHeight(contentFrame) - statusBarYOffset;

    self.backgroundView.frame = self.bounds;

    CGFloat imageXOffset = CRImageViewFrameXOffsetForAlignment(self.toast.imageAlignment, contentFrame.size);
    self.imageView.frame = CGRectMake(imageXOffset,
                                      statusBarYOffset,
                                      imageSize.width == 0 ?
                                      0 :
                                      CGRectGetHeight(contentFrame)-14,
                                      imageSize.height == 0 ?
                                      0 :
                                      CGRectGetHeight(contentFrame)-14);

    CGFloat imageWidth = imageSize.width == 0 ? kCRStatusBarViewNoImageLeftContentInset : CGRectGetMaxX(_imageView.frame);
    CGFloat x = CRContentXOffsetForViewAlignmentAndWidth(self.toast.imageAlignment, imageWidth);

    if (self.toast.showActivityIndicator) {
        CGFloat centerX = CRCenterXForActivityIndicatorWithAlignment(self.toast.activityViewAlignment, CGRectGetHeight(contentFrame), CGRectGetWidth(contentFrame));
        self.activityIndicator.center = CGPointMake(centerX,
                                     CGRectGetMidY(contentFrame) + statusBarYOffset);

        [self.activityIndicator startAnimating];
        x = MAX(CRContentXOffsetForViewAlignmentAndWidth(self.toast.activityViewAlignment, CGRectGetHeight(contentFrame)), x);

        [self bringSubviewToFront:self.activityIndicator];
    }

    BOOL showingImage = imageSize.width > 0;

    CGFloat width = CRContentWidthForAccessoryViewsWithAlignments(CGRectGetWidth(contentFrame),
                                                                  CGRectGetHeight(contentFrame),
                                                                  showingImage,
                                                                  self.toast.imageAlignment,
                                                                  self.toast.showActivityIndicator,
                                                                  self.toast.activityViewAlignment);

    CGFloat buttonX = contentFrame.size.width - 60;
    CGFloat buttonY = 0;
    CGFloat buttonWidth = 60;
    CGFloat buttonHeight = contentFrame.size.height;
    self.closeButton.frame = (CGRect) {buttonX, buttonY, buttonWidth, buttonHeight};

    if (self.toast.subtitleText == nil) {
        self.label.frame = CGRectMake(x,
                                      statusBarYOffset,
                                      width,
                                      CGRectGetHeight(contentFrame));
    } else {

        CGFloat height = MIN([self.toast.text boundingRectWithSize:CGSizeMake(width, 30)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName : self.toast.font}
                                                           context:nil].size.height,
                             CGRectGetHeight(contentFrame));

        height = ceilf(height);
        UIFont *subtitleFont = orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ? self.toast.subtitleFont : [UIFont fontWithName:self.toast.subtitleFont.fontName size:10];
        CGFloat subtitleHeight = [self.toast.subtitleText boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                    attributes:@{NSFontAttributeName : subtitleFont}
                                                                       context:nil].size.height;
        subtitleHeight = ceilf(subtitleHeight);
        if ((CGRectGetHeight(contentFrame) - (height + subtitleHeight)) < 5) {
            subtitleHeight = (CGRectGetHeight(contentFrame) - (height))-10;
        }
        CGFloat offset = (CGRectGetHeight(contentFrame) - (height + subtitleHeight))/2;
        
        if (UIDeviceOrientationIsLandscape(orientation)){
            offset = 0;
            subtitleHeight = 15;
            x += 5;
        }
        self.label.frame = CGRectMake(x,
                                      offset+statusBarYOffset,
                                      CGRectGetWidth(contentFrame)-x-kCRStatusBarViewNoImageRightContentInset- 50,
                                      height);

        self.subtitleLabel.frame = CGRectMake(x,
                                              height+offset+statusBarYOffset,
                                              CGRectGetWidth(contentFrame)-x-kCRStatusBarViewNoImageRightContentInset - 50,
                                              subtitleHeight);
    }

    CGFloat imageDimensionBasedOnOrientation;
    if (UIDeviceOrientationIsLandscape(orientation)) {
        imageDimensionBasedOnOrientation = 24;
    } else {
        imageDimensionBasedOnOrientation = 50;
    }
    _imageView.frame = (CGRect){10, _imageView.frame.origin.y, imageDimensionBasedOnOrientation,imageDimensionBasedOnOrientation};
    _imageView.center = (CGPoint){_imageView.center.x, self.center.y};
    _imageView.layer.cornerRadius = _imageView.frame.size.width/2;
    _imageView.clipsToBounds = YES;
}

#pragma mark - Overrides

- (void)setToast:(CRToast *)toast {
    _toast = toast;
    _label.text = toast.text;
    _label.font = toast.font;
    _label.textColor = toast.textColor;
    _label.textAlignment = toast.textAlignment;
    _label.numberOfLines = toast.textMaxNumberOfLines;
    _label.shadowOffset = toast.textShadowOffset;
    _label.shadowColor = toast.textShadowColor;
    if (toast.subtitleText != nil) {
        _subtitleLabel.text = toast.subtitleText;
        _subtitleLabel.font = toast.subtitleFont;
        _subtitleLabel.textColor = toast.subtitleTextColor;
        _subtitleLabel.textAlignment = toast.subtitleTextAlignment;
        _subtitleLabel.numberOfLines = toast.subtitleTextMaxNumberOfLines;
        _subtitleLabel.shadowOffset = toast.subtitleTextShadowOffset;
        _subtitleLabel.shadowColor = toast.subtitleTextShadowColor;
    }
    _imageView.image = toast.image;
    _imageView.contentMode = toast.imageContentMode;
    _activityIndicator.activityIndicatorViewStyle = toast.activityIndicatorViewStyle;
    self.backgroundColor = toast.backgroundColor;

    if (toast.backgroundView) {
        _backgroundView = toast.backgroundView;
        if (!_backgroundView.superview) {
            [self insertSubview:_backgroundView atIndex:0];
        }
    }
}

@end
