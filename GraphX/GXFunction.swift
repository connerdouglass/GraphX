//
//  GXFunction.swift
//  GraphX
//
//  Created by Conner Douglass on 8/25/14.
//  Copyright (c) 2014 Dapware. All rights reserved.
//

import Foundation

class GXFunction {
    
    var trueExpression : GXMathExpression = GXConstantExpression(value: 0.0)
    
    init(expression : String) {
        
        // Create an expression string format object
        self.trueExpression = GXStringExpression(str: expression)
        
    }
    
    func getValueAtX(x : Float) -> Float {
        
        return self.trueExpression.getValueAtX(x)
        
    }
    
    func getDisplayRepresentation() -> String {
        return self.trueExpression.getName()
    }
    
}