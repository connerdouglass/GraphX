//
//  ViewController.swift
//  GraphX
//
//  Created by Conner Douglass on 8/25/14.
//  Copyright (c) 2014 Dapware. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIAlertViewDelegate {
    
    var graphView : GXGraphView?
                            
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.becomeFirstResponder()
        self.view.backgroundColor = UIColor.redColor()
        
        self.graphView = GXGraphView(frame: self.view.bounds)
        
        // self.graphView!.addFunction(GXFunction(expression: "x^2"))
        // self.graphView!.addFunction(GXFunction(expression: "x^3+3x^2-4"))
        self.graphView!.addFunction(GXFunction(expression: "x^3+3x^2-4"))
        
        self.view.addSubview(graphView!)
        
        var nav : UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 64))
        nav.tintColor = UIColor.whiteColor()
        nav.tintColor = UIColor.blackColor()
        self.view.addSubview(nav)
        
        var item : UINavigationItem = UINavigationItem(title: "GraphX")
        item.rightBarButtonItem = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "addFunction")
        item.leftBarButtonItem = UIBarButtonItem(title: "Origin", style: UIBarButtonItemStyle.Plain, target: self, action: "goToOrigin")
        nav.pushNavigationItem(item, animated: false)
        
    }
    
    func goToOrigin() -> Void {
        
        self.graphView!.zoom = 50.0
        self.graphView!.originShift = (Float(CGRectGetWidth(self.graphView!.frame)) / 2.0, Float(CGRectGetHeight(self.graphView!.frame)) / 2.0)
        self.graphView!.setNeedsDisplay()
        
    }
    
    func alertView(alertView: UIAlertView!, didDismissWithButtonIndex buttonIndex: Int) {
        
        if buttonIndex != alertView.cancelButtonIndex {
            
            var fnString : String = alertView.textFieldAtIndex(0).text
            self.graphView!.addFunction(GXFunction(expression: fnString))
            
        }
        
    }
    
    func addFunction() -> Void {
        
        var alert : UIAlertView = UIAlertView(title: "Function", message: "y=", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Add Function")
        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alert.show()
        
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent!) {
        
        if event.subtype == UIEventSubtype.MotionShake {
            
            println("Shake!")
            self.graphView!.clearFunctions()
            
        }
        
    }

}

