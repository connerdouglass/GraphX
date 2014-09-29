//
//  GXMathExpression.swift
//  GraphX
//
//  Created by Conner Douglass on 8/27/14.
//  Copyright (c) 2014 Dapware. All rights reserved.
//

import Foundation
import QuartzCore

let trigSymbols : [(String, String)] = [
    ("asin",    "\u{05D0}"),
    ("sin",     "\u{05D1}"),
    ("acos",    "\u{05D2}"),
    ("cos",     "\u{05D3}"),
    ("atan",    "\u{05D4}"),
    ("tan",     "\u{05D5}"),
    ("sqrt",    "\u{05D6}")
]

protocol GXMathExpression {
    
    func getValueAtX(x : Float) -> Float
    func getName() -> String
   
}

class GXConstantExpression : GXMathExpression {
    
    var value : Float = 0.0
    
    init(value: Float) {
        
        self.value = value
        
    }
    
    func getValueAtX(x: Float) -> Float {
        
        return self.value
        
    }
    
    func getName() -> String {
        return NSString(format: "%.2f", self.value)
    }
    
}

func getTrigFuncNameForChar(str : String) -> String {
    
    for trigPair : (String, String) in trigSymbols {
        if str == trigPair.1 {
            return trigPair.0
        }
    }
    
    return ""
}

func isCharTrigFunc(str : String) -> Bool {
    
    for trigPair : (String, String) in trigSymbols {
        if str == trigPair.1 {
            return true
        }
    }
    return false
}

class GXStringExpression : GXMathExpression {
    
    var trueExpression : GXMathExpression = GXConstantExpression(value: 0.0)
    
    init(str strRaw : String) {
        
        var str : String = fixParentheses(strRaw)
        if str.hasPrefix("-") {
            str = "0" + str
        }
        
        self.trueExpression = GXConstantExpression(value: 1.0)
        
        for trigPair : (String, String) in trigSymbols {
            str = str.stringByReplacingOccurrencesOfString(trigPair.0, withString: trigPair.1)
        }
        
        var addedAndSubtractedParts : [[String]] = self.getAddedAndSubtractedParts(str)
        var addedParts : [String] = addedAndSubtractedParts[0]
        var subtractedParts : [String] = addedAndSubtractedParts[1]
        
        if addedParts.count + subtractedParts.count > 1 {
            
            self.trueExpression = GXConstantExpression(value: 0.0)
            var isZero : Bool = true
        
            for added : String in addedParts {
                
                var addedExp : GXStringExpression = GXStringExpression(str: added)
                if isZero {
                    self.trueExpression = addedExp
                } else {
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: addedExp, operation: .Add)
                }
                
                isZero = false
                
            }
            
            for subtracted : String in subtractedParts {
                
                var subtractedExp : GXStringExpression = GXStringExpression(str: subtracted)
                if isZero {
                    self.trueExpression = GXMathOperation(expressionA: GXConstantExpression(value: -1.0), expressionB: subtractedExp, operation: .Multiply)
                } else {
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: subtractedExp, operation: .Subtract)
                }
                
                isZero = false
                
            }
            
        } else {
            
            var multParts : ([String], [String]) = self.getMultipliedAndDividedParts(str)
            var isZero : Bool = true
            
            if multParts.0.count + multParts.1.count > 1 {
                
                self.trueExpression = GXConstantExpression(value: 1.0)
            
                for expStr : String in multParts.0 {
                    var exp : GXStringExpression = GXStringExpression(str: expStr)
                    if isZero {
                        self.trueExpression = exp
                    } else {
                        self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: exp, operation: .Multiply)
                    }
                    isZero = false
                }
                for expStr : String in multParts.1 {
                    var exp : GXStringExpression = GXStringExpression(str: expStr)
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: exp, operation: .Divide)
                    isZero = false
                }
                
            } else {
                
                var functionParts : [String] = getFunctionParts(str)
                
                if functionParts.count > 1 {
                    
                    var funcName : String = functionParts[0]
                    var funcInner : String = functionParts[1]
                    
                    var innerFuncPart : GXMathExpression = GXStringExpression(str: funcInner)
                    self.trueExpression = GXSpecialFunction(name: funcName, inside: innerFuncPart)
                    
                } else {
                
                    var exponentParts : [String] = getExponentParts(str)
                    
                    if exponentParts.count > 1 {
                        
                        var base : String = exponentParts[0]
                        var exponent : String = (exponentParts[1] as String)
                        .stringByReplacingOccurrencesOfString("(", withString: "")
                        .stringByReplacingOccurrencesOfString(")", withString: "")
                        
                        var baseExp : GXMathExpression = GXStringExpression(str: base)
                        var expExp : GXMathExpression = GXStringExpression(str: exponent)
                        
                        self.trueExpression = GXMathOperation(expressionA: baseExp, expressionB: expExp, operation: .Exponent)
                        
                    } else {
                        
                        // Should be a constant value, here
                        
                        if str == "x" {
                            
                            self.trueExpression = GXVariableExpression()
                            
                        } else if str == "t" {
                            
                            self.trueExpression = GXTimeVariableExpression()
                            
                        }else {
                            
                            var floatStr : Float = (str as NSString).floatValue
                            self.trueExpression = GXConstantExpression(value: floatStr)
                            
                        }
                        
                    }
                }
            }
        }
        
    }
    
    func getFunctionParts(str : String) -> [String] {
        
        if str.utf16Count == 0 {
            return []
        }
        
        var rawFunc : String = String(Array(str)[0])
        var funcName : String = getTrigFuncNameForChar(rawFunc)
        
        if funcName == "" {
            return []
        }
        
        var theRest : String = ""
        
        for var charIndex : Int = 1; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            theRest += char
            
        }
        
        return [funcName, theRest]
        
    }
    
    func getExponentParts(str : String) -> [String] {
        
        var expIndex : Int = -1
        var depth : Int = 0
        
        for var charIndex : Int = 0; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            
            if char == "(" {
                depth++
            } else if char == ")" {
                depth--
            }
            
            if depth == 0 {
                
                if char == "^" {
                    expIndex = charIndex
                }
                
            }
            
        }
        
        if expIndex < 0 {
            return []
        }
        
        var part0 : String = fixParentheses((str as NSString).substringToIndex(expIndex))
        var part1 : String = fixParentheses((str as NSString).substringFromIndex(expIndex + 1))
        
        return [part0, part1]
        
    }
    
    // Returns an array of the first multiplied part and the rest of the string
    func getFirstMultipliedPart(str : String) -> (String, String, GXMathOperationType) {
        
        var insideFirstElement : Bool = true
        
        var part : String = ""
        var remaining : String = ""
        var depth : Int = 0
        
        var operation : GXMathOperationType = .Multiply
        
        // Loop through every character
        for var charIndex : Int = 0; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            
            if charIndex == 0 && char == "/" {
                operation = .Divide
                continue
            } else if charIndex == 0 && char == "*" {
                operation = .Multiply
                continue
            }
            
            /*
            if !insideFirstElement {
                remaining += char
                continue
            }
             */
            
            if insideFirstElement {
                part += char
            } else {
                remaining += char
                continue
            }
            
            var previousCharacter : String = ""
            var nextCharacter : String = ""
            if charIndex > 0 {
                previousCharacter = String(Array(str)[charIndex - 1])
            }
            if charIndex < str.utf16Count - 1 {
                nextCharacter = String(Array(str)[charIndex + 1])
            }
            
            if char == "(" {
                depth++
            } else if char == ")" {
                depth--
            }
            
            if depth == 0 && !isCharTrigFunc(char) {
                
                // if char != "^" || nextCharacter == "^" {
                if char != "^" && nextCharacter != "^" {
                    
                    if nextCharacter == "/" {
                        insideFirstElement = false
                    } else if nextCharacter == "(" {
                        insideFirstElement = false
                    } else if isCharTrigFunc(nextCharacter) {
                        insideFirstElement = false
                    } else if isCharDigit(char) != isCharDigit(nextCharacter) {
                        insideFirstElement = false
                    }
                    
                }
                
            }
            
            //////
            
        }
        
        /*
        part = fixParentheses(part)
        remaining = fixParentheses(remaining)
        */
        
        return (part, remaining, operation)
        
    }
    
    func getMultipliedAndDividedParts(str : String) -> ([String], [String]) {
        
        var parts : (String, String, GXMathOperationType) = getFirstMultipliedPart(str)
        
        // println(parts.0)
        
        var mult : [String] = []
        var div : [String] = []
        
        if parts.2 == GXMathOperationType.Multiply {
            mult.append(parts.0)
        } else {
            div.append(parts.0)
        }
        
        if parts.1.utf16Count > 0 {
            
            // println("1: " + parts.1)
        
            var otherParts : ([String], [String]) = getMultipliedAndDividedParts(parts.1)
            for ex : String in otherParts.0 {
                mult.append(ex)
            }
            for ex : String in otherParts.1 {
                div.append(ex)
            }
            
        }
        
        return (mult, div)
        
    }
    
    func fixParentheses(str : String) -> String {
        
        if hasRedundantParentheses(str) {
            
            var strOut : String = ""
            var depth : Int = 0
            
            // Loop through every character
            for var charIndex : Int = 0; charIndex < str.utf16Count; charIndex++ {
                
                // Get the character
                var char : String = String(Array(str)[charIndex])
                
                if char == "(" && depth == 0 {
                    // Don't add the character
                } else if char == ")" && depth == 1 {
                    // Don't add this either
                } else {
                    strOut += char
                }
                
                if char == "(" {
                    depth++
                } else if char == ")" {
                    depth--
                }
                
            }
            
            return strOut
            
        }
        
        return str
        
    }
    
    func hasRedundantParentheses(str : String) -> Bool {
        
        var depth : Int = 0
        
        // Loop through every character
        for var charIndex : Int = 0; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            
            
            
            if char == "(" {
                depth++
            } else if char == ")" {
                depth--
            }
            
            if charIndex == 0 && char != "(" {
                
                return false
                
            }
            
            // If we are in the middle
            if charIndex > 0 && charIndex < str.utf16Count - 1 {
                
                // If the depth is not greater than 0
                if depth == 0 {
                    
                    return false
                    
                }
                
            }
            
            if charIndex == str.utf16Count - 1 && char != ")" {
                
                return false
                
            }
            
        }
        
        return true
        
    }
    
    func isCharDigit(c : String) -> Bool {
        
        var allowed : String = "0123456789-.+"
        
        return allowed.componentsSeparatedByString(c).count > 1
        
    }
    
    func getAddedAndSubtractedParts(str : String) -> [[String]] {
        
        // The depth inside parentheses
        var depth : Int = 0
        
        // The current part being added to
        var currentPart : String = ""
        
        // An array of parts
        var partsAdded : [String] = []
        var partsSubtracted : [String] = []
        
        var adding : Bool = true
        
        // Loop through every character
        for var charIndex : Int = 0; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            
            if charIndex == 0 && char == "-" {
                
                currentPart += char
                continue
                
            }
            
            // If we are entering parentheses, add
            if char == "(" {
                
                // Add the character
                currentPart += char
                
                depth++
                
            } else if char == ")" {
                
                // Add the character
                currentPart += char
                
                depth--
                
            } else if (char == "+" || char == "-") && depth == 0 {
                
                // If there is a current part
                if currentPart.utf16Count > 0 {
                    
                    // Add the characters
                    if adding {
                        partsAdded.append(currentPart)
                    } else {
                        partsSubtracted.append(currentPart)
                    }
                    
                    // Clear the old part
                    currentPart = ""
                    
                }
                
                // Are we adding or subtracting?
                adding = (char == "+")
                
            } else {
                
                // Add the character
                currentPart += char
                
            }
            
        }
        
        // If we have unhandled parts
        if currentPart.utf16Count > 0 {
            
            // Add it
            if adding {
                partsAdded.append(currentPart)
            } else {
                partsSubtracted.append(currentPart)
            }
            
        }
        
        /*
        println()
        println("----- BEGIN -----")
        
        for s : String in partsAdded {
            println(" A> " + s)
        }
        for s : String in partsSubtracted {
            println(" S> " + s)
        }
        
        println("-----  END  -----")
        println()
        */
        
        return [partsAdded, partsSubtracted]
        
    }
    
    func getValueAtX(x: Float) -> Float {
        
        return self.trueExpression.getValueAtX(x)
        
    }
    
    func getName() -> String {
        return self.trueExpression.getName()
    }
    
}

let FUNC_SIN : (x: Float) -> Float = {
    (x: Float) in
    return sinf(x)
}

class GXSpecialFunction : GXMathExpression {
    
    var name : String = ""
    var inside : GXMathExpression
    var evalBlock : (x: Float) -> Float
    
    init(name : String, inside: GXMathExpression = GXVariableExpression()) {
        
        self.name = name
        self.inside = inside
        
        if self.name == "sin" {
            self.evalBlock = sinf
        } else if self.name == "asin" {
            self.evalBlock = asinf
        } else if self.name == "cos" {
            self.evalBlock = cosf
        } else if self.name == "acos" {
            self.evalBlock = acosf
        } else if self.name == "tan" {
            self.evalBlock = tanf
        } else if self.name == "atan" {
            self.evalBlock = atanf
        } else if self.name == "sqrt" {
            self.evalBlock = sqrtf
        } else {
            self.evalBlock = { (x: Float) in
                return x
            }
        }
        
    }
    
    func getValueAtX(x: Float) -> Float {
        
        var innerX : Float = self.inside.getValueAtX(x)
        
        return self.evalBlock(x: innerX)
        
        /*
        
        if self.name == "sin" {
            return sinf(innerX)
        } else if self.name == "asin" {
            return asinf(innerX)
        } else if self.name == "cos" {
            return cosf(innerX)
        } else if self.name == "acos" {
            return acosf(innerX)
        } else if self.name == "tan" {
            return tanf(innerX)
        } else if self.name == "atan" {
            return atanf(innerX)
        } else if self.name == "sqrt" {
            return sqrt(innerX)
        }
        
        return 0.0
        */
        
    }
    
    func getName() -> String {
        
        return self.name + " ( " + self.inside.getName() + " ) "
        
    }
    
}

class GXVariableExpression : GXMathExpression {
    
    func getValueAtX(x: Float) -> Float {
        
        return x
        
    }
    
    func getName() -> String {
        return "x"
    }
    
}

class GXTimeVariableExpression : GXMathExpression {
    
    func getValueAtX(x: Float) -> Float {
        
        return Float(CACurrentMediaTime())
        
    }
    
    func getName() -> String {
        return "t"
    }
    
}


enum GXMathOperationType {
    
    case Add
    case Subtract
    case Multiply
    case Divide
    case PlusOrMinus
    case Exponent
    
    func perform(a : Float, b : Float) -> [Float] {
        
        var values : [Float] = []
        
        switch self {
        case .Add:
            values.append(a + b)
        case .Subtract:
            values.append(a - b)
        case .Multiply:
            values.append(a * b)
        case .Divide:
            values.append(a / b)
        case .PlusOrMinus:
            values.append(a + b)
            values.append(a - b)
        case .Exponent:
            values.append(pow(a, b))
        }
        
        return values
        
    }
    
    func getSymbol() -> String {
        switch self {
        case .Add:
            return "+"
        case .Subtract:
            return "-"
        case .Multiply:
            return "*"
        case .Divide:
            return "/"
        case .PlusOrMinus:
            return "(+/-)"
        case .Exponent:
            return "^"
        }
    }
    
}

let OP_MULT : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a * b
}

let OP_ADD : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a + b
}

let OP_SUB : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a - b
}

let OP_DIV : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a / b
}

let OP_POW : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return powf(a, b)
}

class GXMathOperation : GXMathExpression {
    
    // Object properties
    var operationType : GXMathOperationType
    var expressionA : GXMathExpression
    var expressionB : GXMathExpression
    var operationBlock : ((a: Float, b: Float) -> Float)?
    
    // Initializer for the math operation
    init(expressionA : GXMathExpression, expressionB : GXMathExpression, operation : GXMathOperationType) {
        
        self.operationType = operation
        self.expressionA = expressionA
        self.expressionB = expressionB
        
        if operation == GXMathOperationType.Add {
            self.operationBlock = OP_ADD
        } else if operation == GXMathOperationType.Subtract {
            self.operationBlock = OP_SUB
        } else if operation == GXMathOperationType.Divide {
            self.operationBlock = OP_DIV
        } else if operation == GXMathOperationType.Multiply {
            self.operationBlock = OP_MULT
        } else if operation == GXMathOperationType.Exponent {
            self.operationBlock = OP_POW
        } else {
        
            self.operationBlock = {
                (a: Float, b: Float) in
                return self.operationType.perform(a, b: b)[0]
            }
            
        }
        
    }
    
    func getValueAtX(x : Float) -> Float {
        
        var valueA : Float = self.expressionA.getValueAtX(x)
        var valueB : Float = self.expressionB.getValueAtX(x)
        
        return self.operationBlock!(a: valueA, b: valueB)
        
    }
    
    func getName() -> String {
        return "(" + self.expressionA.getName() + " " + self.operationType.getSymbol() + " " + self.expressionB.getName() + ")"
    }
    
}