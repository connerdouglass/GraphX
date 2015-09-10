//
//  GXFunction.swift
//  GraphX
//
//  Created by Conner Douglass on 8/25/14.
//  Copyright (c) 2014 Dapware. All rights reserved.
//

import Foundation

/*
 *  The function class takes a string expression and converts it
 *  to a function that can calculate output values for a given input.
 */
class GXFunction {
    
    // The expression, defaulted to a zero constant
    private var trueExpression : GXMathExpression = GXConstantExpression(value: 0.0)
    
    /*
     *  Initializes a function with the provided string expression
     */
    init(expression : String) {
        
        // Create an expression string format object
        self.trueExpression = GXStringExpression(str: expression)
        
    }
    
    /*
     *  Calculates the output value of the function for a given input
     */
    func getValueAtX(x : Float) -> Float {
        
        // Calculate and return the value
        return self.trueExpression.getValueAtX(x)
        
    }
    
    /*
     *  Converts the function back to a string representation
     */
    func getDisplayRepresentation() -> String {
        
        // Return the name of the expression
        return self.trueExpression.getName()
        
    }
    
}