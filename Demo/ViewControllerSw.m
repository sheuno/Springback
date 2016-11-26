//
//  ViewController.m
//  Springback
//
//  Created by Sheun  Olatunbosun on 10/1/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

#import "ViewControllerSw.h"
#import "SettingsViewController.h"
#import "Springback-Swift.h"

#define NUM_BOXES 8

#define MAX_XPOS 10000
#define MAX_YPOS 8000

@interface ViewControllerSw () <UIPopoverPresentationControllerDelegate>
{
    IBOutlet UILabel *hOffsetLabel;
    IBOutlet UILabel *vOffsetLabel;
    IBOutlet UISlider *hOffsetSlider;
    IBOutlet UISlider *vOffsetSlider;
    IBOutlet UIView *canvasView;
    IBOutlet SpringbackControlSw *springbackControl;
    IBOutlet UIView *xScrollView;
    IBOutlet UIView *yScrollView;
    IBOutlet UILabel *delayLabel;
    IBOutlet UISlider *delaySlider;
    IBOutlet UIBarButtonItem *settingsButton;
    
    CGPoint boxPositions[NUM_BOXES];
    CGFloat currentXScrollPos;
    CGFloat currentYScrollPos;
}

@property(nonatomic,assign) CGSize currentCanvasSize;
@property(nonatomic,strong) NSMutableArray *boxViews;
@property(nonatomic,strong) UIView *xPosView;
@property(nonatomic,strong) UIView *yPosView;

@property(nonatomic,assign) BOOL reversePan;
@property(nonatomic,assign) BOOL boundaryStop;
@property(nonatomic,assign) NSUInteger hCounter;
@property(nonatomic,assign) NSUInteger vCounter;
@end

@implementation ViewControllerSw

#pragma mark - Implementation

- (void)resetBoxView:(NSUInteger)index xSlot:(NSUInteger)xSlot ySlot:(NSUInteger)ySlot
{
    CGSize canvasSize = canvasView.frame.size;
    CGFloat boxWidth = canvasSize.width / 2;
    CGFloat boxHeight = canvasSize.height / 2;
    
    boxPositions[index] = CGPointMake(xSlot * boxWidth, ySlot * boxHeight);
    UIView *v = self.boxViews[index];
    v.frame = CGRectMake(xSlot * boxWidth, ySlot * boxHeight, boxWidth, boxHeight);
}

- (void)resetBoxViews
{
    NSUInteger i = -1;
    
    [self resetBoxView:++i xSlot:0 ySlot:-1];
    [self resetBoxView:++i xSlot:2 ySlot:-1];
    [self resetBoxView:++i xSlot:-1 ySlot:0];
    [self resetBoxView:++i xSlot:1 ySlot:0];
    [self resetBoxView:++i xSlot:0 ySlot:1];
    [self resetBoxView:++i xSlot:2 ySlot:1];
    [self resetBoxView:++i xSlot:-1 ySlot:2];
    [self resetBoxView:++i xSlot:1 ySlot:2];
}

- (void)setupUI
{
    springbackControl.returnDelay = 5;
    springbackControl.deadZone = 40;
    springbackControl.showKnobs = true;
    
    // Parameters
    
    hOffsetSlider.enabled = false;
    vOffsetSlider.enabled = false;
    
    [self updateDelaySliderLabelWithControl:true];
    
    self.reversePan = false;
    self.boundaryStop = false;
    
    self.hCounter = 0;
    self.vCounter = 0;

    // Scrolls pos indicators
    
    self.xPosView = [[UIView alloc] initWithFrame:CGRectZero];
    self.xPosView .backgroundColor = [UIColor blueColor];
    [xScrollView addSubview:self.xPosView];
    
    self.yPosView = [[UIView alloc] initWithFrame:CGRectZero];
    self.yPosView.backgroundColor = [UIColor blueColor];
    [yScrollView addSubview:self.yPosView];
    
    currentXScrollPos = MAX_XPOS / 2;
    currentYScrollPos = MAX_YPOS / 2;
    [self moveScrollPosIndicators];
    
    // Canvas boxes
    
    self.boxViews = [[NSMutableArray alloc] initWithCapacity:NUM_BOXES];
    for (int i = 0; i < NUM_BOXES; ++i)
    {
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor redColor];
        [canvasView addSubview:v];
        [self.boxViews addObject:v];
    }
    [self resetBoxViews];
    self.currentCanvasSize = canvasView.frame.size;
    
    [NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(timerTick) userInfo:nil repeats:true];
}

- (void)updateDelaySliderLabelWithControl:(BOOL)withControl
{
    int returnDelay = (int)springbackControl.returnDelay;
    
    if (withControl)
    {
        delaySlider.value = returnDelay;
    }
    
    delayLabel.text = [NSString stringWithFormat:@"%d", returnDelay];
}

- (void)moveScrollPosIndicators
{
    static int indicatorSide = 20;
    
    CGSize szX = xScrollView.frame.size;
    CGFloat xInView = currentXScrollPos * (szX.width - indicatorSide) / MAX_XPOS;
    self.xPosView.frame = CGRectMake(xInView, 0, indicatorSide, indicatorSide);
    
    CGSize szY = yScrollView.frame.size;
    CGFloat yInView = currentYScrollPos * (szY.height - indicatorSide) / MAX_YPOS;
    self.yPosView.frame = CGRectMake(0, yInView, indicatorSide, indicatorSide);
}

- (void)moveBoxesForXIncrement:(NSInteger)xInc yIncrement:(NSInteger)yInc
{
    CGFloat canvasWidth = canvasView.bounds.size.width;
    CGFloat canvasHeight = canvasView.bounds.size.height;
    CGFloat boxWidth = canvasWidth / 2;
    CGFloat boxHeight = canvasHeight / 2;
    
    for (NSUInteger i = 0; i < NUM_BOXES; ++i)
    {
        CGFloat newX = boxPositions[i].x + xInc;
        CGFloat newY = boxPositions[i].y + yInc;
        
        if (newX > canvasWidth + boxWidth) newX = -boxWidth;
        
        if (newX < -boxWidth) newX = canvasWidth + boxWidth;
        
        if (newY > canvasHeight + boxHeight) newY = -boxHeight;
        
        if (newY < -boxHeight) newY = canvasHeight + boxHeight;
        
        boxPositions[i] = CGPointMake(newX, newY);
        
        UIView *v = self.boxViews[i];
        v.frame = CGRectMake(newX, newY, boxWidth, boxHeight);
    }
}

// convert
//   springback Offset -> timerticks
//
//   0   -> 10000000 (still)
//   1   -> 256 (slow)
//   100 -> 1 (fast)
//
// Using 1/2^x scale, not linear scale

- (CGFloat)timerTicksForOffset:(CGFloat)offset
{
    if (offset == 0.0) return 10000000;

    return powf(2 ,((100 - ABS(offset)) / 12.375));
}

- (void)timerTick
{
    CGFloat currentHOffset = springbackControl.hOffset;
    CGFloat currentVOffset = springbackControl.vOffset;

    if (currentHOffset == 0 && currentVOffset == 0) return;
    
    CGFloat xInc = 0;
    CGFloat yInc = 0;

    if (currentHOffset != 0)
    {
        CGFloat hThreshold = [self timerTicksForOffset:currentHOffset];
        if (++self.hCounter > hThreshold)
        {
            self.hCounter = 0;
            
            if (self.reversePan)
            {
                xInc = (currentHOffset < 0) ? 1 : -1;
            }
            else
            {
                xInc = (currentHOffset < 0) ? -1 : 1;
            }
            
            currentXScrollPos += -1 * xInc; // -1 because scroll directiion is always the opposite to canvas movement
            [self boundaryCheck:&currentXScrollPos increment:&xInc minValue:0 maxValue:MAX_XPOS];
        }
    }

    if (currentVOffset != 0)
    {
        CGFloat vThreshold = [self timerTicksForOffset:currentVOffset];
        if (++self.vCounter > vThreshold)
        {
            self.vCounter = 0;
            
            if (self.reversePan)
            {
                yInc = (currentVOffset < 0) ? 1 : -1;
            }
            else
            {
                yInc = (currentVOffset < 0) ? -1 : 1;
            }
            
            currentYScrollPos += -1 * yInc; // -1 because scroll directiion is always the opposite to canvas movement
            [self boundaryCheck:&currentYScrollPos increment:&yInc minValue:0 maxValue:MAX_YPOS];
        }
    }
    
    [self moveScrollPosIndicators];
    [self moveBoxesForXIncrement:xInc yIncrement:yInc];
}

- (void)boundaryCheck:(CGFloat *)pos increment:(CGFloat *)inc minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue
{
    if (self.boundaryStop)
    {
        if (*pos < minValue)
        {
            *pos = 0;
            *inc = 0;
        }
        else if (*pos > maxValue)
        {
            *pos = maxValue;
            *inc = 0;
        }
    }
    else
    {
        if (*pos < minValue)
        {
            *pos = maxValue;
        }
        else if (*pos > maxValue)
        {
            *pos = minValue;
        }
    }
}

- (void)updateFromSettingsView:(SettingsViewController *)svc
{
    self.reversePan = svc.reversePan;
    self.boundaryStop = svc.boundaryLimit;
    springbackControl.showKnobs = svc.showKnobs;
    springbackControl.enabled = svc.controlEnabled;
}

#pragma mark - GUI events

- (IBAction)valueChanged:(id)sender
{
    if (sender == delaySlider)
    {
        springbackControl.returnDelay = delaySlider.value;
        [self updateDelaySliderLabelWithControl:false];
    }
    else if (sender == springbackControl)
    {
        hOffsetSlider.value = springbackControl.hOffset;
        vOffsetSlider.value = springbackControl.vOffset;
        hOffsetLabel.text = [NSString stringWithFormat:@"%d", (int)springbackControl.hOffset];
        vOffsetLabel.text = [NSString stringWithFormat:@"%d", (int)springbackControl.vOffset];
    }
}

- (IBAction)settingsButtonClicked:(id)sender
{
    SettingsViewController *svc = [SettingsViewController new];
    svc.controlEnabled = springbackControl.enabled;
    svc.showKnobs = springbackControl.showKnobs;
    svc.reversePan = self.reversePan;
    svc.boundaryLimit = self.boundaryStop;
    
    svc.modalPresentationStyle = UIModalPresentationPopover;
    svc.popoverPresentationController.delegate = self;
    
    [self presentViewController:svc animated:true completion:nil];
    UIPopoverPresentationController *ppc = svc.popoverPresentationController;
    ppc.barButtonItem = settingsButton;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews]; // does nothing
    
    if (!CGSizeEqualToSize(self.currentCanvasSize, canvasView.frame.size))
    {
        self.currentCanvasSize = canvasView.frame.size;
        [self resetBoxViews];
        [self moveScrollPosIndicators];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"popoverSettings"])
    {
        SettingsViewController *svc = segue.destinationViewController;
        svc.controlEnabled = springbackControl.enabled;
        svc.showKnobs = springbackControl.showKnobs;
        svc.reversePan = self.reversePan;
        svc.boundaryLimit = self.boundaryStop;
        
        svc.modalPresentationStyle = UIModalPresentationPopover;
        svc.popoverPresentationController.delegate = self;
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    SettingsViewController *svc = (SettingsViewController *)popoverPresentationController.presentedViewController;
    [self updateFromSettingsView:svc];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}
@end
