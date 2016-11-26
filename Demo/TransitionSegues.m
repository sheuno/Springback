//
//  TransitionSegues.m
//  Springback
//
//  Created by Sheun  Olatunbosun on 11/24/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

#import "TransitionSegues.h"

@interface UIStoryboardSegue (CustomSlideTransition)

- (void)transitionUsingXShift:(CGFloat)xShift yshift:(CGFloat)yShift;
@end

@implementation UIStoryboardSegue (CustomSlideTransition)
    // http://stackoverflow.com/questions/30763519/ios-segue-left-to-right

- (void)transitionUsingXShift:(CGFloat)xShift yshift:(CGFloat)yShift
{
    UIViewController *src = self.sourceViewController;
    UIViewController *dst = self.destinationViewController;
    
    [src.view.superview insertSubview:dst.view aboveSubview:src.view];
    CGFloat xOffset= xShift * src.view.frame.size.width;
    CGFloat yOffset = yShift * src.view.frame.size.height;
    dst.view.transform = CGAffineTransformMakeTranslation(xOffset, yOffset);
    
    [UIView animateWithDuration:0.25
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^{
                         dst.view.transform = CGAffineTransformMakeTranslation(0, 0);
                         src.view.transform = CGAffineTransformMakeTranslation(-xOffset, -yOffset);
                     }
                     completion: ^(BOOL finished){
                         [src presentViewController:dst animated:false completion: nil];
                         src.view.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
    ];
}
@end

@implementation FromLeftSegue
- (void)perform
{
    [self transitionUsingXShift:-1.0 yshift:0.0];
}
@end

@implementation FromRightSegue
- (void)perform
{
    [self transitionUsingXShift:1.0 yshift:0.0];
}
@end