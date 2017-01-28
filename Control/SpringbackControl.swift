//
//  SpringbackControlSw.swift
//  Springback
//
//  Created by Sheun  Olatunbosun on 11/20/16.
//  Copyright © 2016 Sheun  Olatunbosun. All rights reserved.
//

import UIKit

@objc @IBDesignable
public class SpringbackControlSw : UIControl {

    /// MARK: parameters
    
    public var maxOffset : UInt {
        get { return MAX_STEP }
    }
    
    public var maxReturnDelay : UInt {
        get { return MAX_RETURN_DELAY }
    }
    
    public var maxDeadZone : UInt {
        get { return MAX_DEAD_ZONE }
    }
    
    // MARK: properties
    
    @IBInspectable public var showKnobs : Bool
    @IBInspectable public var deadZone : UInt {
        didSet {
            if deadZone > MAX_DEAD_ZONE {
                deadZone = MAX_DEAD_ZONE
            }
        }
    }
    
    @IBInspectable public var returnDelay : UInt {
        didSet {
            if returnDelay < 1 {
                returnDelay = 1
            }
            else if returnDelay > MAX_RETURN_DELAY {
                returnDelay = MAX_RETURN_DELAY
            }
        }
    }
    
    public private(set) var hOffset : CGFloat
    public private(set) var vOffset : CGFloat
    
    // MARK: initializers
    
    public override init(frame: CGRect) {
        self.returnDelay = 10
        self.deadZone = 0
        self.showKnobs = true
        self.hOffset = 0.0
        self.vOffset = 0.0
        super.init(frame:frame)
        self.setupKnobViewsAndTimer()
    }
    
    public required init?(coder:NSCoder) {
        self.returnDelay = 10
        self.deadZone = 0
        self.showKnobs = true
        self.hOffset = 0.0
        self.vOffset = 0.0
        super.init(coder:coder)
        self.setupKnobViewsAndTimer()
    }
    
    // MARK: - implementation

    // Tracing with custom flag SBCLOG_LEVEL
    // 0 - none, 1 - minimal, 2 - detail, 3 - noisy!

#if SBCLOG_LEVEL1
        private let maxTraceLevel:UInt = 1
#elseif SBCLOG_LEVEL2
        private let maxTraceLevel:UInt = 2
#elseif SBCLOG_LEVEL3
        private let maxTraceLevel:UInt = 3
#else
        private let maxTraceLevel:UInt = 0
#endif
    
    private func SBCLog(_ level:UInt, _ format:String, _ args:CVarArg...) -> Void
    {
        if (level <= maxTraceLevel)
        {
            withVaList(args){
                NSLogv(format, $0)
            }
        }
    }
    
    // constants
    
    private let KNOB_SIZE : UInt = 40
    private let MAX_STEP  : UInt = 100
    private let MAX_RETURN_DELAY : UInt = 50
    private let MAX_DEAD_ZONE : UInt = 30
    
    // properties (internal)
    
    private var originKnobView : KnobView?
    private var knobView : KnobView?
    
    private var isDraggingKnob = false
    private var origin : CGPoint = CGPoint.zero
    private var deltaX : CGFloat = 0.0
    private var deltaY : CGFloat = 0.0
    private var stepCountDown : UInt = 0
    private var currentPosition : CGPoint = CGPoint.zero
    private var tickCounter : UInt = 0
    
    private func setupKnobViewsAndTimer() -> Void
    {
        let kbs = CGFloat(KNOB_SIZE)
        self.knobView = KnobView(frame:CGRect(x: 0, y: 0, width: kbs, height: kbs))
        self.knobView!.backgroundColor = UIColor.clear
        self.knobView!.tintColor = UIColor.black
        self.addSubview(self.knobView!)
        
        self.originKnobView = KnobView(frame:CGRect(x: 0, y: 0, width: kbs, height: kbs))
        self.originKnobView!.backgroundColor = UIColor.clear
        self.originKnobView!.tintColor = UIColor.white
        self.addSubview(self.originKnobView!)
        
        self.knobView!.isHidden = true
        self.originKnobView!.isHidden = true
        
        let sel = #selector(SpringbackControlSw.timerTick)
        Timer.scheduledTimer(timeInterval: 0.001, target:self, selector:sel, userInfo:nil, repeats:true)
    }
    
    @objc private func timerTick(_ tm: Timer)
    {
        self.tickCounter += 1
        
        if (self.tickCounter % self.returnDelay == 0)
        {
            if (self.isDraggingKnob)
            {
                // Don't attempt to return to origin if user is still moving the knob
                self.calculateOffsets()
            }
            else
            {
                if (self.performReturnToOrigin())
                {
                    self.moveKnobView(self.knobView!, toPoint:self.currentPosition)
                    self.calculateOffsets()
                    
                    if (self.stepCountDown == 0)
                    {
                        self.originKnobView!.isHidden = true
                        self.knobView!.isHidden = true
                    }
                }
            }
        }
    }
    
    override public var isEnabled : Bool
    {
        didSet {
            if (isEnabled)
            {
                let hideKnobs = !self.showKnobs || (self.hOffset == 0 && self.vOffset == 0);
                self.knobView!.isHidden = hideKnobs;
                self.originKnobView!.isHidden = hideKnobs;
                self.backgroundColor = UIColor.clear
                self.alpha = 1.0;
            }
            else
            {
                self.knobView!.isHidden = true;
                self.originKnobView!.isHidden = true;
                self.backgroundColor = UIColor.black
                self.alpha = 0.5
            }
        }
    }
    
    private func calculateOffsets()
    {
        // Ensure that the calculated Offset inside the dead zone (dz), near the origin,
        // evaluates to zero. This is square as opposed to circular but... meh
        let dz = CGFloat(self.deadZone)
        let dzViewWidth = self.bounds.size.width - dz
        let dzViewHeight = self.bounds.size.height - dz
        
        assert (dzViewWidth > 0 && dzViewHeight > 0)
        
        let dzDeltaX = self.adjustValue(self.deltaX, forDeadZone:dz)
        let dzDeltaY = self.adjustValue(self.deltaY, forDeadZone:dz)
        
        var newHOffset = dzDeltaX / dzViewWidth * CGFloat(self.stepCountDown)
        var newVOffset = dzDeltaY / dzViewHeight * CGFloat(self.stepCountDown)
        
        // Capping
        let maxStep = CGFloat(MAX_STEP)
        
        if (newHOffset < -maxStep) { newHOffset = -maxStep }
        
        if (newHOffset > maxStep) { newHOffset = maxStep }
        
        if (newVOffset < -maxStep) { newVOffset = -maxStep }
        
        if (newVOffset > maxStep) { newVOffset = maxStep }
        
        
        let didChange = (self.hOffset != newHOffset) || (self.vOffset != newVOffset)
        
        self.hOffset = newHOffset
        self.vOffset = newVOffset
        
        if didChange
        {
            SBCLog(3, "New Offset H: %.f, V: %.f", self.hOffset, self.vOffset);
            self.sendOffsetChangeAlert()
        }
    }
    
    private func adjustValue(_ v:CGFloat, forDeadZone dz:CGFloat) -> CGFloat
    {
        if (v > -dz && v < dz) { return 0 }
        
        if (v < 0) { return v+dz }
        
        return v-dz
    }
    
    private func moveKnobView(_ v:UIView, toPoint p:CGPoint)
    {
        if (self.showKnobs)
        {
            let ks = CGFloat(KNOB_SIZE)
            let r = CGRect(x: p.x - ks/2, y: p.y - ks/2, width: ks, height: ks)
            v.frame = r
            v.isHidden = false
        }
    }
    
    private func sendOffsetChangeAlert()
    {
        self.sendActions(for: UIControlEvents.valueChanged)
    }
    
    private func performReturnToOrigin() -> Bool
    {
        if self.stepCountDown == 0 { return false } // do nothing
        
        self.stepCountDown -= 1
        
        let x = self.origin.x + (self.deltaX * CGFloat(self.stepCountDown)) / CGFloat(MAX_STEP)
        let y = self.origin.y + (self.deltaY * CGFloat(self.stepCountDown)) / CGFloat(MAX_STEP)
        
        self.currentPosition = CGPoint(x: x, y: y)
        return true
    }
    
    private func handleTouchDownAtPoint(_ p:CGPoint)
    {
        self.origin = p;
        self.stepCountDown = 0;
        self.deltaX = 0;
        self.deltaY = 0;
        self.hOffset = 0;
        self.vOffset = 0;
        
        self.moveKnobView(self.originKnobView!, toPoint:p)
        self.moveKnobView(self.knobView!, toPoint:p)
        
        self.isDraggingKnob = false;
        
        self.sendOffsetChangeAlert()
    }
    
    private func handleTouchUpAtPoint(_ p:CGPoint)
    {
        if self.stepCountDown == 0 {
            // No dragging took place
            self.originKnobView!.isHidden = true
            self.knobView!.isHidden = true
        }
        self.isDraggingKnob = false;
    }
    
    private func handleDragToPoint(_ p:CGPoint)
    {
        self.currentPosition = p
        self.stepCountDown = MAX_STEP
        self.deltaX = self.currentPosition.x - self.origin.x
        self.deltaY = self.currentPosition.y - self.origin.y
        
        self.moveKnobView(self.knobView!, toPoint:p)
        
        self.isDraggingKnob = true;
    }

    // MARK: Touch Events
    
    public override func beginTracking(_ touch:UITouch, with event:UIEvent?) -> Bool
    {
        let p = touch.location(in: self)
        SBCLog(1, "Begin tracking -> %.f, %.f", p.x, p.y);
        self.handleTouchDownAtPoint(p)
        return true;
    }
    
    public override func continueTracking(_ touch:UITouch, with event:UIEvent?) -> Bool
    {
        let p = touch.location(in: self)
        SBCLog(2, "Continue tracking --> %.f, %.f", p.x, p.y);
        self.handleDragToPoint(p)
        return true;
    }
    
    public override func endTracking(_ touch:UITouch?, with event:UIEvent?)
    {
        if let tch = touch {
            let p = tch.location(in: self)
            SBCLog(1, "End tracking --> %.f, %.f", p.x, p.y);
            self.handleTouchUpAtPoint(p)
        }
    }
    
    // MARK: Drawing
    public override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        // Simple outline border rect
        
        if self.isEnabled {
            self.tintColor.setStroke()
        }
        else {
            UIColor.gray.setStroke()
        }
        let drawArea = self.bounds;
        let ctxt = UIGraphicsGetCurrentContext();
        ctxt?.stroke(drawArea, width: 4.0);
    }
}


// MARK: - KnobView

private class KnobView : UIView {
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        self.tintColor.setStroke()
        let ctxt = UIGraphicsGetCurrentContext()
        ctxt?.setLineWidth(3.0)
        var r = self.frame
        r = CGRect(x: r.origin.x + 3.0, y: r.origin.y + 3.0, width: r.size.width - 2 * 3.0, height: r.size.height - 2 * 3.0)
        ctxt?.strokeEllipse(in: r)
    }
}
