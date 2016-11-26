//
//  SpringbackControl.m
//  Springback
//
//  Created by Sheun  Olatunbosun on 10/1/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

#ifdef DEBUG
#ifndef SBCLOG_LEVEL
#define SBCLOG_LEVEL 1
// 0 - none, 1 - minimal, 2 - detail, 3 - noisy!
#endif
#endif

#ifdef DEBUG
#  define SBCLog(level, ...)  if (level <= SBCLOG_LEVEL) NSLog(__VA_ARGS__)
#else
#  define SBCLog(level, ...)
#endif


#import "SpringbackControl.h"

#define KNOB_SIZE 40
#define MAX_STEP 100
#define MAX_RETURN_DELAY 50
#define MAX_DEAD_ZONE 30


@interface KnobView : UIView
@end

@implementation KnobView

- (void)drawRect:(CGRect)rect
{
    [self.tintColor setStroke];
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctxt, 3.0);
    CGRect r = self.frame;
    r = CGRectMake(r.origin.x + 3.0, r.origin.y + 3.0, r.size.width - 2 * 3.0, r.size.height - 2 * 3.0);
    CGContextStrokeEllipseInRect(ctxt, r);
}

@end

@interface SpringbackControl ()

@property (nonatomic,assign) BOOL isDraggingKnob;
@property (nonatomic,strong) KnobView *originKnobView;
@property (nonatomic,strong) KnobView *knobView;

@property (nonatomic,assign) CGPoint origin;
@property (nonatomic,assign) CGFloat deltaX;
@property (nonatomic,assign) CGFloat deltaY;
@property (nonatomic,assign) NSUInteger stepCountDown;
@property (nonatomic,assign) CGPoint currentPosition;

@property (nonatomic,assign) NSUInteger tickCounter;

// public
@property (nonatomic,assign) CGFloat hOffset;
@property (nonatomic,assign) CGFloat vOffset;
@end

@implementation SpringbackControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initDefaults];
    }
    return self;
}

- (void)initDefaults
{
    self.returnDelay = 10;
    self.deadZone = 0;
    self.showKnobs = true;
    
    self.knobView = [[KnobView alloc] initWithFrame:CGRectMake(0, 0, KNOB_SIZE, KNOB_SIZE)];
    self.knobView.backgroundColor = [UIColor clearColor];
    self.knobView.tintColor = [UIColor blackColor];
    [self addSubview:self.knobView];
    
    self.originKnobView = [[KnobView alloc] initWithFrame:CGRectMake(0, 0, KNOB_SIZE, KNOB_SIZE)];
    self.originKnobView.backgroundColor = [UIColor clearColor];
    self.originKnobView.tintColor = [UIColor whiteColor];
    [self addSubview:self.originKnobView];
    
    self.knobView.hidden = true;
    self.originKnobView.hidden =true;
    
    self.isDraggingKnob = false;
    self.stepCountDown = 0;
    
    self.origin = CGPointZero;
    self.currentPosition = CGPointZero;
    
    [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(timerTick) userInfo:nil repeats:true];
}

- (void)setReturnDelay:(NSUInteger)returnDelay
{
    if (returnDelay < 1) returnDelay = 1;
    
    if (returnDelay > MAX_RETURN_DELAY) returnDelay = MAX_RETURN_DELAY;
    
    _returnDelay = returnDelay;
}

- (void)setDeadZone:(NSUInteger)deadZone
{
    if (deadZone > MAX_DEAD_ZONE) deadZone = MAX_DEAD_ZONE;
    
    _deadZone = deadZone;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (enabled)
    {
        BOOL hideKnobs = !self.showKnobs || (self.hOffset == 0 && self.vOffset == 0);
        self.knobView.hidden = hideKnobs;
        self.originKnobView.hidden = hideKnobs;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 1.0;
        
    }
    else
    {
        self.knobView.hidden = true;
        self.originKnobView.hidden = true;
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.5;
    }
}

- (void)moveKnobView:(UIView *)v toPoint:(CGPoint)p
{
    if (self.showKnobs)
    {
        CGRect r = CGRectMake(p.x - KNOB_SIZE/2, p.y - KNOB_SIZE/2, KNOB_SIZE, KNOB_SIZE);
        v.frame = r;
        v.hidden = false;
    }
}

- (void)sendOffsetChangeAlert
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (CGFloat)adjustValue:(CGFloat)v forDeadZone:(CGFloat)dz
{
    if (v > -dz && v < dz) return 0;
    
    if (v < 0) return v+dz;
    
    return v-dz;
}

- (void)calculateOffsets
{
    // Ensure that the calculated Offset inside the dead zone (dz), near the origin,
    // evaluates to zero. This is square as opposed to circular but... meh
    
    CGFloat dzViewWidth = self.bounds.size.width - self.deadZone;
    CGFloat dzViewHeight = self.bounds.size.height - self.deadZone;
    
    assert (dzViewWidth > 0 && dzViewHeight > 0);
    
    CGFloat dzDeltaX = [self adjustValue:self.deltaX forDeadZone:self.deadZone];
    CGFloat dzDeltaY = [self adjustValue:self.deltaY forDeadZone:self.deadZone];
    
    CGFloat newHOffset = dzDeltaX / dzViewWidth * self.stepCountDown;
    CGFloat newVOffset = dzDeltaY / dzViewHeight * self.stepCountDown;
    
    // Capping
    if (newHOffset < -MAX_STEP) newHOffset = -MAX_STEP;
    
    if (newHOffset > MAX_STEP) newHOffset = MAX_STEP;
    
    if (newVOffset < -MAX_STEP) newVOffset = -MAX_STEP;
    
    if (newVOffset > MAX_STEP) newVOffset = MAX_STEP;
    
    
    BOOL didChange = (self.hOffset != newHOffset) || (self.vOffset != newVOffset);
    
    self.hOffset = newHOffset;
    self.vOffset = newVOffset;
    
    if (didChange)
    {
        SBCLog(3, @"New Offset H: %.f, V: %.f", self.hOffset, self.vOffset);
        [self sendOffsetChangeAlert];
    }
}

- (BOOL)performReturnToOrigin
{
    if (self.stepCountDown == 0) return false; // do nothing
    
    --self.stepCountDown;
    
    CGFloat x = self.origin.x + (self.deltaX * self.stepCountDown) / MAX_STEP;
    CGFloat y = self.origin.y + (self.deltaY * self.stepCountDown) / MAX_STEP;
    
    self.currentPosition = CGPointMake(x, y);
    return true;
}

- (void)timerTick
{
    ++self.tickCounter;
    
    if (self.tickCounter % self.returnDelay == 0)
    {
        if (self.isDraggingKnob)
        {
            // Don't attempt to return to origin if user is still moving the knob
            [self calculateOffsets];
        }
        else
        {
            if ([self performReturnToOrigin])
            {
                [self moveKnobView:self.knobView toPoint:self.currentPosition];
                [self calculateOffsets];
                
                if (self.stepCountDown == 0)
                {
                    self.originKnobView.hidden = true;
                    self.knobView.hidden = true;
                }
            }
        }
    }
}

- (void)handleTouchDownAtPoint:(CGPoint)p
{
    self.origin = p;
    self.stepCountDown = 0;
    self.deltaX = 0;
    self.deltaY = 0;
    self.hOffset = 0;
    self.vOffset = 0;
    
    [self moveKnobView:self.originKnobView toPoint:p];
    [self moveKnobView:self.knobView toPoint:p];
    
    self.isDraggingKnob = false;
    
    [self sendOffsetChangeAlert];
}

- (void)handleTouchUpAtPoint:(CGPoint)p
{
    if (self.stepCountDown == 0)
    {
        // No dragging took place
        self.originKnobView.hidden = true;
        self.knobView.hidden = true;
        
    }
    self.isDraggingKnob = false;
}

- (void)handleDragToPoint:(CGPoint)p
{
    self.currentPosition = p;
    self.stepCountDown = MAX_STEP;
    self.deltaX = self.currentPosition.x - self.origin.x;
    self.deltaY = self.currentPosition.y - self.origin.y;
    
    [self moveKnobView:self.knobView toPoint:p];
    
    self.isDraggingKnob = true;
}


#pragma mark - Touch Events

- (BOOL)beginTrackingWithTouch:(UITouch *)touch
                     withEvent:(UIEvent *)event
{
    CGPoint p = [touch locationInView:self];
    SBCLog(1, @"Begin tracking -> %.f, %.f", p.x, p.y);
    [self handleTouchDownAtPoint:p];
    return true;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch
                        withEvent:(UIEvent *)event
{
    CGPoint p = [touch locationInView:self];
    SBCLog(2, @"Continue tracking --> %.f, %.f", p.x, p.y);
    [self handleDragToPoint:p];
    return true;
}

- (void)endTrackingWithTouch:(UITouch *)touch
                   withEvent:(UIEvent *)event
{
    CGPoint p = [touch locationInView:self];
    SBCLog(1, @"End tracking --> %.f, %.f", p.x, p.y);
    [self handleTouchUpAtPoint:p];
}

#pragma mark - view

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    // Simple outline border rect
    
    if (self.enabled)
    {
        [self.tintColor setStroke];
    }
    else
    {
        [[UIColor grayColor] setStroke];
    }
    CGRect drawArea = self.bounds;
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextStrokeRectWithWidth(ctxt, drawArea, 4.0);
}


#pragma mark - ranges

+ (NSUInteger)maxOffset
{
    return MAX_STEP;
}

+ (NSUInteger)maxReturnDelay
{
    return MAX_RETURN_DELAY;
}

+ (NSUInteger)maxDeadZone
{
    return MAX_DEAD_ZONE;
}
@end
