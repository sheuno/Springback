//
//  TransitionSegues.swift
//  Springback
//
//  Created by sodev on 7/8/17.
//  Copyright © 2017 Sheun  Olatunbosun. All rights reserved.
//

import UIKit

extension UIStoryboardSegue {
    func transition(usingXShift xShift:CGFloat, yShift:CGFloat){
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        let xOffset = xShift * src.view.frame.size.width
        let yOffset = yShift * src.view.frame.size.height
        dst.view.transform = CGAffineTransform(translationX: xOffset, y: yOffset)
        UIView.animate(withDuration: 0.25, animations: { 
            dst.view.transform = CGAffineTransform(translationX:0, y:0)
            src.view.transform = CGAffineTransform(translationX:-xOffset, y:-yOffset)
        }) { (_) in
            src.present(dst, animated:false, completion: nil)
            src.view.transform = CGAffineTransform(translationX:0, y:0)
        }
    }
}

class FromLeftSegue : UIStoryboardSegue
{
    override public func perform() {
        self.transition(usingXShift:-1.0, yShift:0.0)
    }
}

class FromRightSegue : UIStoryboardSegue
{
    override public func perform() {
        self.transition(usingXShift:1.0, yShift:0.0)
    }
}
