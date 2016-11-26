//
//  SettingsViewController.m
//  Springback
//
//  Created by Sheun  Olatunbosun on 10/22/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
{
    IBOutlet UISwitch *controlEnabledSwitch;
    IBOutlet UISwitch *showKnobsSwitch;
    IBOutlet UISwitch *reversePanSwitch;
    IBOutlet UISwitch *boundaryLimitSwitch;
}
@end

@implementation SettingsViewController

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    controlEnabledSwitch.on = self.controlEnabled;
    showKnobsSwitch.on = self.showKnobs;
    reversePanSwitch.on = self.reversePan;
    boundaryLimitSwitch.on = self.boundaryLimit;
}

- (IBAction)switchClicked:(id)sender
{
    UISwitch *switchControl = sender;
    
    if (switchControl == controlEnabledSwitch) self.controlEnabled = switchControl.isOn;
    
    if (switchControl == showKnobsSwitch) self.showKnobs = switchControl.isOn;
    
    if (switchControl == reversePanSwitch) self.reversePan = switchControl.isOn;
    
    if (switchControl == boundaryLimitSwitch) self.boundaryLimit = switchControl.isOn;
}
@end
