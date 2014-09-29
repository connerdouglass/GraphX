//
//  GXGraphView.swift
//  GraphX
//
//  Created by Conner Douglass on 8/29/14.
//  Copyright (c) 2014 Dapware. All rights reserved.
//

import UIKit

let graphColors : [UIColor] = [
    UIColor.redColor(),
    UIColor.blueColor(),
    UIColor.greenColor(),
    UIColor.orangeColor(),
    UIColor.purpleColor(),
    UIColor.blackColor()
]

func timeTest(block: () -> Void) -> Float {
    
    var time0 : Float = Float(CACurrentMediaTime())
    
    block()
    
    var time1 : Float = Float(CACurrentMediaTime())
    
    return time1 - time0
    
}

class GXGraphView: UIView, UIGestureRecognizerDelegate {
    
    var functions : [GXFunction] = []
    var displayLink : CADisplayLink?
    var changed : Bool = true
    
    var originShift : (Float, Float) = (0.0, 0.0)
    var graphScale : Float = 1.0
    
    let zoomRange : (Float, Float) = (1.0, 1500.0)
    
    var zoom : Float {
        get {
            return 1.0 / self.graphScale
        }
        set (newVal) {
            self.graphScale = 1.0 / max(zoomRange.0, min(zoomRange.1, newVal))
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.whiteColor()
        
        self.displayLink = CADisplayLink(target: self, selector: "update")
        self.displayLink!.frameInterval = 1
        self.displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.layer.drawsAsynchronously = true
        
        self.userInteractionEnabled = true
        
        self.originShift = (Float(CGRectGetWidth(frame)) / 2.0, Float(CGRectGetHeight(frame)) / 2.0)
        
        self.zoom = 50.0
        
        var pinch : UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
        pinch.delegate = self
        self.addGestureRecognizer(pinch)
        
        var pan : UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        pan.minimumNumberOfTouches = 1
        pan.delegate = self
        self.addGestureRecognizer(pan)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    func handlePan(pan: UIPanGestureRecognizer) -> Void {
        
        var translation : CGPoint = pan.translationInView(self)
        self.originShift.0 += Float(translation.x)
        self.originShift.1 -= Float(translation.y)
        pan.setTranslation(CGPointZero, inView: self)
        
        if pan.state == UIGestureRecognizerState.Ended {
            // Slide to finish
        }
        
        self.changed = true
        
    }
    
    func handlePinch(pinch: UIPinchGestureRecognizer) -> Void {
            
        self.zoom *= Float(pinch.scale)
        pinch.scale = 1.0
        
        self.changed = true
        
    }
    
    func setVisibleWidth(width : Float) -> Void {
        self.graphScale = Float(CGRectGetWidth(self.frame)) / width
    }
    
    func setVisibleHeight(height : Float) -> Void {
        self.graphScale = Float(CGRectGetHeight(self.frame)) / height
    }
    
    func getVisibleWidth() -> Float {
        return Float(CGRectGetWidth(self.frame)) / self.graphScale
    }
    
    func getVisibleHeight() -> Float {
        return Float(CGRectGetHeight(self.frame)) / self.graphScale
    }
    
    func getMinVisibleX() -> Float {
        return (self.originShift.0 * self.graphScale) - self.getVisibleWidth() / 2
    }
    
    func getMaxVisibleX() -> Float {
        return (self.originShift.0 * self.graphScale) + self.getVisibleWidth() / 2
    }
    
    func getMinVisibleY() -> Float {
        return (self.originShift.1 * self.graphScale) - self.getVisibleHeight() / 2
    }
    
    func getMaxVisibleY() -> Float {
        return (self.originShift.1 * self.graphScale) + self.getVisibleHeight() / 2
    }
    
    func graphToScreenX(graphX: Float) -> Int {
        return toIntSafe(graphX / self.graphScale - (-self.originShift.0))
    }
    
    func screenToGraphX(screenX: Int) -> Float {
        return self.graphScale * (-self.originShift.0 + Float(screenX))
    }
    
    func toIntSafe(f : Float) -> Int {
        var fBounded : Float = max(Float(Int.min), min(Float(Int.max), f))
        return Int(fBounded)
    }
    
    func graphToScreenY(graphY: Float) -> Int {
        return Int(CGRectGetHeight(self.frame)) - toIntSafe(graphY / self.graphScale - (-self.originShift.1))
    }
    
    func screenToGraphY(screenY: Int) -> Float {
        return self.graphScale * (-self.originShift.1 + Float(screenY))
    }
    
    func graphToScreenCoord(graphX: Float, graphY: Float) -> (Int, Int) {
        return (graphToScreenX(graphX), graphToScreenY(graphY))
    }
    
    func screenToGraphCoord(screenX: Int, screenY: Int) -> (Float, Float) {
        return (screenToGraphX(screenX), screenToGraphY(screenY))
    }
    
    func update() -> Void {
        
        if self.changed {
            self.setNeedsDisplay()
        }
        
    }
    
    override func drawRect(rect: CGRect) {
        
        // let scale : Float = 1.0
        let xDrawPrecision : CGFloat = 2.0
        let limitTestSpan : Float = 0.1
        
        // Get the width and height of the view
        var width : Int = Int(CGRectGetWidth(self.frame)/* * CGFloat(scale)*/)
        var height : Int = Int(CGRectGetHeight(self.frame)/* * CGFloat(scale)*/)
        
        let context : CGContextRef = UIGraphicsGetCurrentContext()
        
        if true {
            
            CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextFillRect(context, self.bounds)
            
            var origin : (Int, Int) = self.graphToScreenCoord(0.0, graphY: 0.0)
            
            CGContextSetLineWidth(context, 2.0)
            CGContextSetStrokeColorWithColor(context, UIColor(white: 0.0, alpha: 1.0).CGColor)
            
            // X-Intercept
            CGContextMoveToPoint(context, 0.0, CGFloat(origin.1))
            CGContextAddLineToPoint(context, CGFloat(width), CGFloat(origin.1))
            
            // Y-Intercept
            CGContextMoveToPoint(context, CGFloat(origin.0), 0.0)
            CGContextAddLineToPoint(context, CGFloat(origin.0), CGFloat(height))
            
            CGContextStrokePath(context)
        }
        
        var time : CFTimeInterval = CACurrentMediaTime()
        
        CGContextSetLineWidth(context, 2.0)
        CGContextSetLineJoin(context, kCGLineJoinRound)
        
        for var i : Int = 0; i < self.functions.count; i++ {
            
            CGContextSetStrokeColorWithColor(context, graphColors[i % graphColors.count].CGColor)
            
            var olderX : CGFloat = 0.0
            var olderY : CGFloat = 0.0
            
            var lastX : CGFloat = 0.0
            var lastY : CGFloat = 0.0
            
            var lastGraphY : CGFloat = 0.0
            var olderGraphY : CGFloat = 0.0
            
            for var x : CGFloat = -xDrawPrecision; x <= CGFloat(width) + xDrawPrecision; x += xDrawPrecision {
                
                var graphX : CGFloat = CGFloat(self.screenToGraphX(Int(x)))
                var graphY : CGFloat = CGFloat(self.functions[i].getValueAtX(Float(graphX)))
                
                var thisX : CGFloat = CGFloat(x)
                var thisY : CGFloat = CGFloat(graphToScreenY(Float(graphY)))
                
                if x == -xDrawPrecision {
                    lastX = thisX
                    lastY = thisY
                    olderX = thisX
                    olderY = thisY
                }
                
                if lastGraphY.isFinite && graphY.isFinite {
                
                    CGContextMoveToPoint(context, lastX, lastY)
                    CGContextAddLineToPoint(context, thisX, thisY)
                    
                } else {
                    
                    if lastGraphY < 0 {
                    
                        CGContextMoveToPoint(context, thisX, CGFloat.max)
                        
                    } else if lastGraphY > 0 {
                        
                        CGContextMoveToPoint(context, thisX, CGFloat.min)
                        
                    }
                    
                }
                
                olderX = lastX
                olderY = lastY
                lastX = thisX
                lastY = thisY
                olderGraphY = lastGraphY
                lastGraphY = graphY
                
            }
            
            CGContextStrokePath(context)
            
        }
        
        self.changed = false
        
        // println(NSString(format: "Elapsed: %.2f ms", 1000.0 * (CACurrentMediaTime() - time)))
        println(self.zoom)
        
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addFunction(function: GXFunction) -> Void {
        
        self.functions.append(function)
        println(function.getDisplayRepresentation())
        self.changed = true
        
    }
    
    func clearFunctions() -> Void {
        
        self.functions.removeAll(keepCapacity: false)
        self.changed = true
        
    }

}
