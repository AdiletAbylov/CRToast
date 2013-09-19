//
//  UIViewController+CWStatusBarNotification.m
//  CWStatusBarNotificationDemo
//
//  Created by Cezary Wojcik on 9/18/13.
//  Copyright (c) 2013 Cezary Wojcik. All rights reserved.
//

#import "UIViewController+CWStatusBarNotification.h"
#import <objc/runtime.h>

@implementation UIViewController (CWStatusBarNotification);

#define STATUS_BAR_HEIGHT 22.0f
#define STATUS_BAR_ANIMATION_LENGTH 0.25f
#define FONT_SIZE 12.0f

NSString const *CWStatusBarIsHiddenKey = @"CWStatusBarIsHiddenKey";
NSString const *CWStatusBarNotificationIsShowingKey = @"CWStatusBarNotificationIsShowingKey";
NSString const *CWStatusBarNotificationLabelKey = @"CWStatusBarNotificationLabelKey";

# pragma mark - helper functions
// The below functions produce warnings - not an issue

- (BOOL)prefersStatusBarHidden {
    return self.statusBarIsHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

# pragma mark - dimensions

- (CGFloat)getStatusBarWidth {
    if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        return [UIScreen mainScreen].bounds.size.width;
    }
    return [UIScreen mainScreen].bounds.size.height;
}

- (CGRect)getStatusBarHiddenFrame {
    return CGRectMake(0, -1*STATUS_BAR_HEIGHT, [self getStatusBarWidth], STATUS_BAR_HEIGHT);
}

- (CGRect)getStatusBarFrame {
    return CGRectMake(0, 0, [self getStatusBarWidth], STATUS_BAR_HEIGHT);
}

# pragma mark - show status bar notification function

- (void)showStatusBarNotification:(NSString *)message forDuration:(CGFloat)duration {
    if (!self.statusBarNotificationIsShowing) {
        self.statusBarNotificationIsShowing = YES;
        self.statusBarNotificationLabel.frame = [self getStatusBarHiddenFrame];
        self.statusBarNotificationLabel.text = message;
        self.statusBarNotificationLabel.textAlignment = NSTextAlignmentCenter;
        self.statusBarNotificationLabel.adjustsFontSizeToFitWidth = YES;
        self.statusBarNotificationLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.view addSubview:self.statusBarNotificationLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenOrientationChanged) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        [UIView animateWithDuration:STATUS_BAR_ANIMATION_LENGTH animations:^{
            self.statusBarIsHidden = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            self.statusBarNotificationLabel.frame = [self getStatusBarFrame];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration - 2*STATUS_BAR_ANIMATION_LENGTH animations:^{

            } completion:^(BOOL finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [UIView animateWithDuration:STATUS_BAR_ANIMATION_LENGTH animations:^{
                        self.statusBarIsHidden = NO;
                        [self setNeedsStatusBarAppearanceUpdate];
                        self.statusBarNotificationLabel.frame = [self getStatusBarHiddenFrame];
                    } completion:^(BOOL finished) {
                        [self.statusBarNotificationLabel removeFromSuperview];
                        self.statusBarNotificationIsShowing = NO;
                        [[NSNotificationCenter defaultCenter] removeObserver:self];
                    }];
                });
            }];
        }];
    }
}

- (IBAction)txtFieldEditingDidEnd:(UITextField *)sender {
}

# pragma mark - screen orientation change

- (void)screenOrientationChanged {
    self.statusBarNotificationLabel.frame = [self getStatusBarFrame];
}

# pragma mark - getters/setters

- (void)setStatusBarIsHidden:(BOOL)statusBarIsHidden {
    objc_setAssociatedObject(self, &CWStatusBarIsHiddenKey, [NSNumber numberWithBool:statusBarIsHidden], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)statusBarIsHidden {
    return [objc_getAssociatedObject(self, &CWStatusBarIsHiddenKey) boolValue];
}

- (void)setStatusBarNotificationIsShowing:(BOOL)statusBarNotificationIsShowing {
    objc_setAssociatedObject(self, &CWStatusBarNotificationIsShowingKey, [NSNumber numberWithBool:statusBarNotificationIsShowing], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)statusBarNotificationIsShowing {
    return [objc_getAssociatedObject(self, &CWStatusBarNotificationIsShowingKey) boolValue];
}

- (void)setStatusBarNotificationLabel:(UILabel *)statusBarNotificationLabel {
    objc_setAssociatedObject(self, &CWStatusBarNotificationLabelKey, statusBarNotificationLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILabel *)statusBarNotificationLabel
{
    if (objc_getAssociatedObject(self, &CWStatusBarNotificationLabelKey) == nil) {
        [self setStatusBarNotificationLabel:[UILabel new]];
    }
    return objc_getAssociatedObject(self, &CWStatusBarNotificationLabelKey);
}

@end