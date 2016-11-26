//
//  SpringbackControl.h
//  Springback
//
//  Created by Sheun  Olatunbosun on 10/1/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface SpringbackControl : UIControl

@property (nonatomic,assign) IBInspectable BOOL showKnobs;
@property (nonatomic,assign) IBInspectable NSUInteger deadZone;     // Range is 0 .. maxDeadZone
@property (nonatomic,assign) IBInspectable NSUInteger returnDelay;  // Range is 1 (fastest) .. maxReturnDelay(slowest)
@property (nonatomic,readonly) CGFloat hOffset;     // Range is 0..maxOffset. Can be negative
@property (nonatomic,readonly) CGFloat vOffset;     // Range is 0..maxOffset. Can be negative

// Limits for various properties

+ (NSUInteger)maxOffset;
+ (NSUInteger)maxReturnDelay;
+ (NSUInteger)maxDeadZone;

@end
