//
//  ViewController.swift
//  Springback
//
//  Created by sodev on 7/8/17.
//  Copyright © 2017 Sheun  Olatunbosun. All rights reserved.
//

import UIKit

class ViewController:
    UIViewController,
    UIPopoverPresentationControllerDelegate {
    

    @IBOutlet var hOffsetLabel: UILabel!
    @IBOutlet var vOffsetLabel: UILabel!
    @IBOutlet var hOffsetSlider: UISlider!
    @IBOutlet var vOffsetSlider: UISlider!
    @IBOutlet var canvasView: UIView!
    @IBOutlet var springbackControl: SpringbackControlSw!
    @IBOutlet var xScrollView: UIView!
    @IBOutlet var yScrollView: UIView!
    @IBOutlet var delayLabel: UILabel!
    @IBOutlet var delaySlider: UISlider!
    @IBOutlet var settingsButton: UIBarButtonItem!
    
    // MARK: - Implementation
    
    static let NUM_BOXES = 8
    static let MAX_XPOS: CGFloat = 10000
    static let MAX_YPOS: CGFloat = 8000
    
    private var boxPositions = Array(repeating: CGPoint(x:0, y:0), count: 10)
    private var currentXScrollPos: CGFloat = 0.0
    private var currentYScrollPos: CGFloat = 0.0
    
    private var currentCanvasSize = CGSize(width: 0, height: 0)
    private var boxViews = [UIView]()
    private var xPosView: UIView!
    private var yPosView: UIView!
    
    private var reversePan = true
    private var boundaryStop = true
    private var hCounter: UInt = 0
    private var vCounter: UInt = 0
    
    private func update(fromSettingsView svc: SettingsViewController){
        reversePan = svc.reversePan
        boundaryStop = svc.boundaryLimit
        springbackControl.showKnobs = svc.showKnobs
        springbackControl.isEnabled = svc.controlEnabled
    }

     
    private func resetBoxView(_ index:UInt, xSlot:Int, ySlot:Int) {
        let canvasSize = canvasView.frame.size
        let boxWidth = canvasSize.width / 2
        let boxHeight = canvasSize.height / 2

        let xs = CGFloat(xSlot)
        let ys = CGFloat(ySlot)
        boxPositions[Int(index)] = CGPoint(x: xs * boxWidth, y: ys * boxHeight)
        
        let boxFrame = CGRect(x: xs * boxWidth, y: ys * boxHeight, width: boxWidth, height: boxHeight)
        boxViews[Int(index)].frame = boxFrame
    }

    private func resetBoxViews() {
        let boxSlots:[(Int,Int)] = [
            (0, -1), (2, -1), (-1, 0), (1, 0),
            (0, 1), (2, 1), (-1, 2), (1, 2)
        ]
        
        var i:UInt = 0
        boxSlots.forEach { (slotSpec) in
            resetBoxView(i, xSlot:slotSpec.0, ySlot:slotSpec.1)
            i += 1
        }
    }
    
    
    private func updateDelaySliderLabel(withControl:Bool) {
        let returnDelay = springbackControl.returnDelay

        if withControl {
        delaySlider.value = Float(returnDelay)
        }

        delayLabel.text = "\(Int(returnDelay))"
    }

    static private let indicatorSide: CGFloat = 20
     
    private func moveScrollPosIndicators() {
        let side = ViewController.indicatorSide
        let szX = xScrollView.frame.size
        let xInView = currentXScrollPos * (szX.width - side) / ViewController.MAX_XPOS
        xPosView.frame = CGRect(x: xInView, y: 0, width: side, height: ViewController.indicatorSide)

        let szY = yScrollView.frame.size
        let yInView = currentYScrollPos * (szY.height - side) / ViewController.MAX_YPOS
        yPosView.frame = CGRect(x: 0, y: yInView, width: side, height: side)
    }

     private func moveBoxes(forXIncrement xInc:CGFloat, yIncrement yInc:CGFloat) {
         let canvasWidth = canvasView.bounds.size.width
         let canvasHeight = canvasView.bounds.size.height
         let boxWidth = canvasWidth / 2
         let boxHeight = canvasHeight / 2
        
         for i in 0 ..< ViewController.NUM_BOXES {
             var newX = boxPositions[i].x + xInc
             var newY = boxPositions[i].y + yInc
             
             if (newX > canvasWidth + boxWidth) { newX = -boxWidth }
             
             if (newX < -boxWidth) { newX = canvasWidth + boxWidth }
             
             if (newY > canvasHeight + boxHeight) { newY = -boxHeight }
             
             if (newY < -boxHeight) { newY = canvasHeight + boxHeight }
             
             boxPositions[i] = CGPoint(x: newX, y: newY)
             
             let v = boxViews[i]
             v.frame = CGRect(x: newX, y: newY, width: boxWidth, height: boxHeight)
        }
    }

    private func boundaryCheck(_ aValue: inout CGFloat, withIncrement inc: inout CGFloat, minValue:CGFloat,  maxValue:CGFloat) {
        if boundaryStop {
            if (aValue < minValue) {
                aValue = 0
                inc = 0
            }
            else if aValue > maxValue {
                aValue = maxValue
                inc = 0
            }
        }
        else {
            if aValue < minValue {
                aValue = maxValue;
            }
            else if aValue > maxValue {
                aValue = minValue;
            }
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

    private func timerTicks(forOffset offset: CGFloat) -> UInt
    {
        if offset == 0.0 { return 10000000 }

        return UInt(powf(2 , (Float(100.0 - abs(offset)) / 12.375)))
    }
    
    @objc
    private func timerTick() {
        let currentHOffset = springbackControl.hOffset
        let currentVOffset = springbackControl.vOffset

        if (currentHOffset == 0 && currentVOffset == 0) { return }

        var xInc: CGFloat = 0
        var yInc: CGFloat = 0

        if currentHOffset != 0.0 {
            let hThreshold = timerTicks(forOffset: currentHOffset)
            hCounter += 1
            if hCounter > hThreshold {
                hCounter = 0

                if (self.reversePan) {
                    xInc = (currentHOffset < 0) ? 1 : -1
                }
                else {
                    xInc = (currentHOffset < 0) ? -1 : 1
                }

                currentXScrollPos += -1 * xInc // -1 because scroll directiion is always the opposite to canvas movement
                boundaryCheck(&currentXScrollPos, withIncrement:&xInc, minValue:0, maxValue:ViewController.MAX_XPOS)
            }
        }

        if currentVOffset != 0.0 {
            let vThreshold = timerTicks(forOffset:currentVOffset)
            vCounter += 1
            if vCounter > vThreshold {
            vCounter = 0;

            if self.reversePan {
                yInc = (currentVOffset < 0) ? 1 : -1;
            }
            else {
                yInc = (currentVOffset < 0) ? -1 : 1;
            }

            currentYScrollPos += -1 * yInc // -1 because scroll directiion is always the opposite to canvas movement
            boundaryCheck(&currentYScrollPos, withIncrement:&yInc, minValue:0, maxValue:ViewController.MAX_YPOS)
            }
        }

        moveScrollPosIndicators()
        moveBoxes(forXIncrement:xInc, yIncrement:yInc)
    }

    private func setupUI() {
        springbackControl.returnDelay = 5
        springbackControl.deadZone = 40
        springbackControl.showKnobs = true

        // Parameters

        hOffsetSlider.isEnabled = false
        vOffsetSlider.isEnabled = false

        updateDelaySliderLabel(withControl: true)

        reversePan = false
        boundaryStop = false

        hCounter = 0;
        vCounter = 0;

        // Scrolls pos indicators

        xPosView = UIView(frame:CGRect.zero)
        xPosView.backgroundColor = UIColor.blue
        xScrollView.addSubview(xPosView)

        yPosView = UIView(frame:CGRect.zero)
        yPosView.backgroundColor = UIColor.blue
        yScrollView.addSubview(yPosView)

        currentXScrollPos = ViewController.MAX_XPOS / 2;
        currentYScrollPos = ViewController.MAX_YPOS / 2;
        moveScrollPosIndicators()
     
        // Canvas boxes

        boxViews = [UIView]()
        for _ in 0 ..< ViewController.NUM_BOXES {
            let v = UIView(frame: CGRect.zero)
            v.backgroundColor = UIColor.red
            canvasView.addSubview(v)
            boxViews.append(v)
        }

        resetBoxViews()
        currentCanvasSize = canvasView.frame.size

        Timer.scheduledTimer(timeInterval: 0.0001, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
     }

    
    // MARK: - GUI events
    
    @IBAction func valueChanged(_ sender: Any?) {
        if sender as? UISlider == delaySlider {
            springbackControl.returnDelay = UInt(delaySlider.value)
            updateDelaySliderLabel(withControl:false)
        }
        else if sender as? SpringbackControlSw == springbackControl {
            hOffsetSlider.value = Float(springbackControl.hOffset)
            vOffsetSlider.value = Float(springbackControl.vOffset)
            hOffsetLabel.text = "\(Int(springbackControl.hOffset))"
            vOffsetLabel.text = "\(Int(springbackControl.vOffset))"
        }
    }
    
    @IBAction func settingsButtonClicked(_ sender: Any?) {
        let svc = SettingsViewController.create()
        svc.controlEnabled = springbackControl.isEnabled
        svc.showKnobs = springbackControl.showKnobs
        svc.reversePan = self.reversePan
        svc.boundaryLimit = self.boundaryStop
        
        svc.modalPresentationStyle = .popover
        svc.popoverPresentationController?.delegate = self
        
        present(svc, animated:true, completion:nil)
        let ppc = svc.popoverPresentationController
        ppc?.barButtonItem = settingsButton
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        let svc = popoverPresentationController.presentedViewController as! SettingsViewController
        self.update(fromSettingsView: svc)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews() // does nothing
        
        if !currentCanvasSize.equalTo(canvasView.frame.size) {
            currentCanvasSize = canvasView.frame.size;
            resetBoxViews()
            moveScrollPosIndicators()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popoverSettings" {
            let svc = segue.destination as! SettingsViewController
            svc.controlEnabled = springbackControl.isEnabled
            svc.showKnobs = springbackControl.showKnobs;
            svc.reversePan = self.reversePan;
            svc.boundaryLimit = self.boundaryStop;
            
            svc.modalPresentationStyle = .popover
            svc.popoverPresentationController?.delegate = self;
        }
    }
}
