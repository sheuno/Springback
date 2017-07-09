//
//  SettingsController.swift
//  Springback
//
//  Created by sodev on 7/8/17.
//  Copyright © 2017 Sheun  Olatunbosun. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var controlEnabledSwitch: UISwitch!
    @IBOutlet var showKnobsSwitch: UISwitch!
    @IBOutlet var reversePanSwitch: UISwitch!
    @IBOutlet var boundaryLimitSwitch: UISwitch!
    
    public var controlEnabled: Bool = true
    public var showKnobs: Bool = true
    public var reversePan: Bool = false
    public var boundaryLimit: Bool = true
    
    static func create() -> SettingsViewController {
        let sb = UIStoryboard(name:"Main", bundle:nil)
        return sb.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
    }
    
    @IBAction func switchClicked(_ sender: Any?) {
        if let sender = sender as? UISwitch{
            switch sender {
            case controlEnabledSwitch:
                controlEnabled = sender.isOn
                break
            case showKnobsSwitch:
                showKnobs = sender.isOn
                break
            case reversePanSwitch:
                reversePan = sender.isOn
                break
            case boundaryLimitSwitch:
                boundaryLimit = sender.isOn
                break
            default:
                break
            }
        }
    }
    // MARK: ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlEnabledSwitch.isOn = self.controlEnabled
        showKnobsSwitch.isOn = self.showKnobs
        reversePanSwitch.isOn = self.reversePan
        boundaryLimitSwitch.isOn = self.boundaryLimit
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
