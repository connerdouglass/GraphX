//
//  GXMathExpression.swift
//  GraphX
//
//  Created by Conner Douglass on 8/27/14.
//  Copyright (c) 2014 Conner Douglass. All rights reserved.
//

import Foundation

// QuartzCore is used for calculating the current time
import QuartzCore

/*
 *  Define some symbolic equivalents to these function names
 *  that will be used in the place of these functions for 
 *  easier parsing.
 */
let trigSymbols : [(String, String)] = [
    ("asin",    "\u{05D0}"),
    ("sin",     "\u{05D1}"),
    ("acos",    "\u{05D2}"),
    ("cos",     "\u{05D3}"),
    ("atan",    "\u{05D4}"),
    ("tan",     "\u{05D5}"),
    ("sqrt",    "\u{05D6}")
]

/*
 *  The math expression protocol is an abstract representation
 */
protocol GXMathExpression {
    
    /*
     *  Calculates the value of the function at the input value x
     */
    func getValueAtX(x : Float) -> Float
    
    /*
     *  Returns the name of the function
     */
    func getName() -> String
   
}

/*
 *  The constant expression protocol is an expression that always
 *  has the same value, irrespective of input.
 */
class GXConstantExpression : GXMathExpression {
    
    /*
     *  The value property contains the value of the constant
     */
    private var value : Float = 0.0
    
    /*
     *  Initializes the expression with the value of the constant
     */
    init(value: Float) {
        
        // Copy over the value of the constant provided
        self.value = value
        
    }
    
    /*
     *  Calculates the value of the constant given the x input, which
     *  will always be the value 'x'
     */
    func getValueAtX(x: Float) -> Float {
        
        // Return the value of the constant
        return self.value
        
    }
    
    /*
     *  Returns the name of the constant
     */
    func getName() -> String {
        
        // Format the constant out to a string
        return NSString(format: "%.2f", self.value) as String
    }
    
}

/*
 *  Gets the name of the trigonometric function given the character, as
 *  defined above.
 */
func getTrigFuncNameForChar(str : String) -> String {
    
    // Loop through the pairs of trig function pairs
    for trigPair : (String, String) in trigSymbols {
        
        // If the characters match
        if str == trigPair.1 {
            
            // Return the string name for the function
            return trigPair.0
        }
    }
    
    // Return a default value
    return ""
}

/*
 *  Determines whether or not the provided character is the character
 *  representing a trigonometric function
 */
func isCharTrigFunc(str : String) -> Bool {
    
    // Loop through the pairs of trig functions
    for trigPair : (String, String) in trigSymbols {
        
        // If the trig function is equivalent to the provided value
        if str == trigPair.1 {
            
            // Return true, this is a trig function
            return true
        }
    }
    
    // Return false, none of them matched
    return false
}

/*
 *  The String expression class defines an expression that is created from a string.
 *  This class works recursively to split the string up and again parse the substrings.
 */
class GXStringExpression : GXMathExpression {
    
    /*
     *  The true expression value
     */
    private var trueExpression : GXMathExpression = GXConstantExpression(value: 0.0)
    
    /*
     *  Initializes a string expression with the provided string value
     */
    init(str strRaw : String) {
        
        // Fix errors with mismatched parentheses in the expression
        var str : String = fixParentheses(strRaw)
        
        // If the string starts with a negative sign
        if str.hasPrefix("-") {
            
            // Turn the string into subtraction problem! Kinda hacky
            str = "0" + str
        }
        
        // Set the true expression value to a default constant value
        self.trueExpression = GXConstantExpression(value: 1.0)
        
        // Loop through the trig names
        for trigPair : (String, String) in trigSymbols {
            
            // Replace the trig function names with the character
            str = str.stringByReplacingOccurrencesOfString(trigPair.0, withString: trigPair.1)
        }
        
        // Separate the string expression into a series of parts that are added and subtracted
        var addedAndSubtractedParts : [[String]] = self.getAddedAndSubtractedParts(str)
        
        // Get the selection of these parts that are all added together
        var addedParts : [String] = addedAndSubtractedParts[0]
        
        // Get the other selection of these parts that are subtracted from the total
        var subtractedParts : [String] = addedAndSubtractedParts[1]
        
        // If there are more parts than simply one
        if addedParts.count + subtractedParts.count > 1 {
            
            // Define the expression value to the additive identity: 0
            self.trueExpression = GXConstantExpression(value: 0.0)
            
            // Track whether or not the value is still zero
            var isZero : Bool = true
        
            // Loop through the added parts in the
            for added : String in addedParts {
                
                // Turn the expression substring into a separate string expression
                var addedExp : GXStringExpression = GXStringExpression(str: added)
                
                // If we haven't yet added a value
                if isZero {
                    
                    // Set the true expression value to this first expression
                    // This prevents us from getting a bunch of "0 + x" artifacts
                    // and ensures the same token shows up as just "x"
                    self.trueExpression = addedExp
                    
                } else {
                    
                    // Add the previous expression to this new string expression
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: addedExp, operation: .Add)
                    
                }
                
                // The value of the expression is no longer zero
                isZero = false
                
            }
            
            // Loop through the subtracted parts in the string
            for subtracted : String in subtractedParts {
                
                // Get the expression that is being subtracted
                var subtractedExp : GXStringExpression = GXStringExpression(str: subtracted)
                
                // If this is the first expression
                if isZero {
                    
                    // Set the true expression to a negative version of the expression being subtracted
                    self.trueExpression = GXMathOperation(expressionA: GXConstantExpression(value: -1.0), expressionB: subtractedExp, operation: .Multiply)
                    
                } else {
                    
                    // Subtract this expression from the previous expression value
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: subtractedExp, operation: .Subtract)
                    
                }
                
                // The value of this expression is no longer zero
                isZero = false
                
            }
            
        // If there is really just one part to the expression
        } else {
            
            // Looks like a good time to separate this token up into its multiplied and divided parts
            var multParts : ([String], [String]) = self.getMultipliedAndDividedParts(str)
            
            // Track the number of parts that have been multiplied or divided so far
            var isZero : Bool = true
            
            // If there are multiplication parts to loop through
            if multParts.0.count + multParts.1.count > 1 {
                
                // Set the default expression value to the multiplicative identity: 1
                self.trueExpression = GXConstantExpression(value: 1.0)
            
                // Loop through the parts being multiplied together
                for expStr : String in multParts.0 {
                    
                    // Get this multiplied part as an expression of its own
                    var exp : GXStringExpression = GXStringExpression(str: expStr)
                    
                    // If this is the first part added to the expression
                    if isZero {
                        
                        // Set the expression to just this token
                        self.trueExpression = exp
                        
                    } else {
                        
                        // Multiply the previous expression by this expression
                        self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: exp, operation: .Multiply)
                        
                    }
                    
                    // The value of the expression is no longer zero
                    isZero = false
                }
                
                // Loop through the divided parts
                for expStr : String in multParts.1 {
                    
                    // Get the expression being divided
                    var exp : GXStringExpression = GXStringExpression(str: expStr)
                    
                    // Set the true epression to the current value divided by this value
                    self.trueExpression = GXMathOperation(expressionA: self.trueExpression, expressionB: exp, operation: .Divide)
                    
                    // The value is no longer zero. Lowering this flag to 'false' is not important,
                    // because this is the last part and we always divide with a 1 in the numerator.
                    isZero = false
                }
                
            // If there is just one part, no multiplication or anything
            } else {
                
                // Divide the string into function parts
                var functionParts : [String] = getFunctionParts(str)
                
                // If there are sub-parts to the function
                if functionParts.count > 1 {
                    
                    // Get the name of the function
                    var funcName : String = functionParts[0]
                    
                    // Get the inner content to the function
                    var funcInner : String = functionParts[1]
                    
                    // Convert the inner part to an expression
                    var innerFuncPart : GXMathExpression = GXStringExpression(str: funcInner)
                    
                    // Convert the entire thing into a function expression
                    self.trueExpression = GXSpecialFunction(name: funcName, inside: innerFuncPart)
                    
                // If there is only one part
                } else {
                
                    // Get the exponential parts
                    var exponentParts : [String] = getExponentParts(str)
                    
                    // If there are exponential parts
                    if exponentParts.count > 1 {
                        
                        // Get the base of the exponential
                        var base : String = exponentParts[0]
                        
                        // Get the exponential part of the expression
                        var exponent : String = (exponentParts[1] as String)
                        .stringByReplacingOccurrencesOfString("(", withString: "")
                        .stringByReplacingOccurrencesOfString(")", withString: "")
                        
                        // Convert the base to a math expression
                        var baseExp : GXMathExpression = GXStringExpression(str: base)
                        
                        // Convert the exponent part to a math expression
                        var expExp : GXMathExpression = GXStringExpression(str: exponent)
                        
                        // Set the true expression of this object to an exponential operation
                        self.trueExpression = GXMathOperation(expressionA: baseExp, expressionB: expExp, operation: .Exponent)
                        
                    // If there are no exponential parts. It's probably a constant
                    } else {
                        
                        // If the value is the 'x' variable
                        if str == "x" {
                            
                            // Set the true expression value to the variable expression
                            self.trueExpression = GXVariableExpression()
                            
                        // If the value is the 't' variable
                        } else if str == "t" {
                            
                            // Set the true expression value to the time variable expression
                            self.trueExpression = GXTimeVariableExpression()
                          
                        // If it is something else, probably a constant number
                        } else {
                            
                            // Get the string value as a float
                            var floatStr : Float = (str as NSString).floatValue
                            
                            // Set the expression value to the constant expression of the float
                            self.trueExpression = GXConstantExpression(value: floatStr)
                            
                        }
                        
                    }
                }
            }
        }
        
    }
    
    /*
     *  Converts the string value to a function call, returning an array containing
     *  the name of the function and the argument to the function, in that order
     */
    func getFunctionParts(str : String) -> [String] {
        
        // If the length of the string is zero
        if count(str) == 0 {
            
            // Return an empty set
            return []
        }
        
        // Get the raw name of the function as a special character
        var rawFunc : String = String(Array(str)[0])
        
        // Get the function's name based on the special character
        var funcName : String = getTrigFuncNameForChar(rawFunc)
        
        // If the function name is not defined
        if funcName == "" {
            
            // Return an empty set
            return []
        }
        
        // Create storage for the rest of the contents
        // var theRest : String = ""
        
        // Get the rest of the parts of the contents
        var theRest : String = (str as NSString).substringFromIndex(1)
        
        // Loop through the parts of the
        /*
        for var charIndex : Int = 1; charIndex < str.utf16Count; charIndex++ {
            
            // Get the character
            var char : String = String(Array(str)[charIndex])
            theRest += char
            
        }
        */
        
        // Return the set of the name and the arguments
        return [funcName, theRest]
        
    }
    
    /*
     *  Separates the parts of the string into the largest exponential grouping.
     *  The first component of the array is the base of the exponential, and the
     *  second component of the array is the power of the exponent
     */
    func getExponentParts(str : String) -> [String] {
        
        // Count the index of the exponent character
        var expIndex : Int = -1
        
        // Track the parenthetical depth of the current character
        var depth : Int = 0
        
        // Convert the string to an array of characters
        var characters: Array = Array(str)
        
        // Loop through the characters in the string
        for var charIndex : Int = 0; charIndex < count(str); charIndex++ {
            
            // Get the character at the index
            var char : String = String(characters[charIndex])
            
            // If the character is an opening parentheses
            if char == "(" {
                
                // Increase the depth
                depth++
                
            // If the character is a closing parentheses
            } else if char == ")" {
                
                // Decrease the depth
                depth--
                
            }
            
            // If we are at the root level of the statement and this is an exponential character
            if depth == 0 && char == "^" {
                
                // Save this index as the exponential index
                expIndex = charIndex
                
            }
            
        }
        
        // If there is no exponential index
        if expIndex < 0 {
            
            // Return an empty set
            return []
        }
        
        // Get the part before the exponential symbol (the base)
        var part0 : String = fixParentheses((str as NSString).substringToIndex(expIndex))
        
        // Get the part after (the exponent)
        var part1 : String = fixParentheses((str as NSString).substringFromIndex(expIndex + 1))
        
        // Return the array of the two parts
        return [part0, part1]
        
    }
    
    // Returns an array of the first multiplied part and the rest of the string
    /*
     *  Looks at the string and finds the first part of the string that
     *  is multiplied with the other parts of the string
     */
    func getFirstMultipliedPart(str : String) -> (String, String, GXMathOperationType) {
        
        // Track whether or not we are inside the first element
        var insideFirstElement : Bool = true
        
        // The first multiplied part of the token
        var part : String = ""
        
        // The remaining parts of the string
        var remaining : String = ""
        
        // The parenthetical depth
        var depth : Int = 0
        
        // Define the operation of the
        var operation : GXMathOperationType = .Multiply
        
        // Convert the string to an array of characters
        var characters: Array = Array(str)
        
        // Loop through every character in the string
        for var charIndex : Int = 0; charIndex < count(str); charIndex++ {
            
            // Get the character
            var char : String = String(characters[charIndex])
            
            // If this is the first character and it is a division symbol
            if charIndex == 0 && char == "/" {
                
                // Set the operation to division
                operation = .Divide
                
                // Continue past this character
                continue
                
            // If this is the first character and the character is a multiplication symbol
            } else if charIndex == 0 && char == "*" {
                
                // The operation is multiplication
                operation = .Multiply
                
                // Continue past this character
                continue
                
            }
            
            // If we are inside the first element still
            if insideFirstElement {
                
                // Append the character to the first part
                part += char
                
            // If we are no longer in the first element
            } else {
                
                // Append the character to the rest of the string
                remaining += char
                
                // Continue past this character
                continue
                
            }
            
            // Create space for the previous character
            var previousCharacter : String = ""
            
            // Create space for the next character
            var nextCharacter : String = ""
            
            // If there is a previous character
            if charIndex > 0 {
                
                // Get the previous character
                previousCharacter = String(characters[charIndex - 1])
            
            }
            
            // If there is a next character
            if charIndex < count(str) - 1 {
                
                // Get the next character
                nextCharacter = String(Array(str)[charIndex + 1])
            
            }
            
            // If the current character is an opening parentheses
            if char == "(" {
                
                // Increase the parenthetical depth
                depth++
                
            // If the current character is a closing parentheses
            } else if char == ")" {
                
                // Decrease the parenthetical depth
                depth--
                
            }
            
            // If we are at the root level and this character is not a trig function
            if depth == 0 && !isCharTrigFunc(char) {
                
                // If neither this character not the next is an exponential
                if char != "^" && nextCharacter != "^" {
                    
                    // If the next character is a division symbol
                    if nextCharacter == "/" {
                        
                        // We are now outside the first element
                        insideFirstElement = false
                        
                    // If the next character is an opening parentheses
                    } else if nextCharacter == "(" {
                        
                        // We are now outside the first element
                        insideFirstElement = false
                        
                    // If the next character is a trig function
                    } else if isCharTrigFunc(nextCharacter) {
                        
                        // We are now outside the first element
                        insideFirstElement = false
                        
                    // If the current character is the beginning or end of a number
                    } else if isCharDigit(char) != isCharDigit(nextCharacter) {
                        
                        // We are now outside the first element
                        insideFirstElement = false
                        
                    }
                    
                }
                
            }
            
        }
        
        // Return the set of the parts
        return (part, remaining, operation)
        
    }
    
    /*
     *  Retrieves the multiplied and divided parts of the string.
     *  The first part of the set is an array containing all multiplied parts.
     *  The second part of the set is an array containing all divided parts.
     */
    func getMultipliedAndDividedParts(str: String) -> ([String], [String]) {
        
        // Get the first part of the string being multiplied
        var parts: (String, String, GXMathOperationType) = getFirstMultipliedPart(str)
        
        // Create storage for the multiplied and divided parts
        var mult: [String] = []
        var div: [String] = []
        
        // If the first part is being multiplied
        if parts.2 == GXMathOperationType.Multiply {
            
            // Append the multiplied part to its respective array
            mult.append(parts.0)
            
        // If the first part is being divided
        } else {
            
            // Append the divided part to its respective array
            div.append(parts.0)
            
        }
        
        // If the first part has contents
        if count(parts.1) > 0 {
            
            // Get the multiplied and divided parts of the right part
            var otherParts : ([String], [String]) = getMultipliedAndDividedParts(parts.1)
            
            // Loop through the multiplied parts
            for ex : String in otherParts.0 {
                
                // Append the multiplied part to the array
                mult.append(ex)
                
            }
            
            // Loop through the divided parts
            for ex : String in otherParts.1 {
                
                // Append the divided part to the array
                div.append(ex)
                
            }
            
        }
        
        // Return a collection of the multiplied and divided arrays
        return (mult, div)
    }
    
    /*
     *  Fixes parentheses on the provided string. If the entire string is a single token wrapped
     *  by one block of parentheses, it will remove them, leaving the untouched inner contents.
     */
    func fixParentheses(str : String) -> String {
        
        // If the string has unnecessary parentheses
        if hasRedundantParentheses(str) {
            
            // Create the output string value
            var strOut : String = ""
            
            // Track the parenthetical depth
            var depth : Int = 0
            
            // Create an array of characters
            var characters: Array = Array(str)
            
            // Loop through every character
            for var charIndex : Int = 0; charIndex < count(str); charIndex++ {
                
                // Get the character at this index
                var char : String = String(characters[charIndex])
                
                // If the character is an opening parentheses at the root level
                if char == "(" && depth == 0 {
                    
                    // Don't add the character
                
                // If the character is bringing us back to root depth
                } else if char == ")" && depth == 1 {
                    
                    // Don't add this either
                
                // If it is any other character
                } else {
                    
                    // Append the character to the output string
                    strOut += char
                    
                }
                
                // If the character is an opening parentheses
                if char == "(" {
                    
                    // Increase the depth
                    depth++
                    
                // If the character is a closing parentheses
                } else if char == ")" {
                    
                    // Decrease the depth
                    depth--
                    
                }
                
            }
            
            // Return the string value
            return strOut
            
        }
        
        // Since there were no parentheses to fix, return the string itself
        return str
        
    }
    
    /*
     *  Determines whether or not the string has unnecessary parentheses wrapping it
     */
    func hasRedundantParentheses(str : String) -> Bool {
        
        // Track the depth of the parentheses
        var depth: Int = 0
        
        // Create an array of characters
        var characters: Array = Array(str)
        
        // Loop through every character
        for var charIndex: Int = 0; charIndex < count(str); charIndex++ {
            
            // Get the character at the index
            var char: String = String(characters[charIndex])
            
            // If the character is opening a grouping
            if char == "(" {
                
                // Increase the depth
                depth++
                
            // If the character is closing a grouping
            } else if char == ")" {
                
                // Decrease the depth
                depth--
                
            }
            
            // If this is the first character and the character is NOT an opening parentheses
            if charIndex == 0 && char != "(" {
                
                // Return false. This is not redundantly grouped
                return false
                
            }
            
            // If we are in the middle somewhere
            if charIndex > 0 && charIndex < count(str) - 1 {
                
                // If we are at the root depth
                if depth == 0 {
                    
                    // We are clearly not grouped
                    return false
                    
                }
                
            }
            
            // If this is the final character and it is a closing parentheses
            if charIndex == count(str) - 1 && char != ")" {
                
                // Return false, this is not redundantly grouped
                return false
                
            }
            
        }
        
        // We never caught a reason to suggest it is not redundant. Return true by default
        return true
        
    }
    
    /*
     *  Determines whether or not the character provided is part of a number
     */
    func isCharDigit(c: String) -> Bool {
        
        // Define the list of permitted characters
        let allowed : String = "0123456789-.+"
        
        // Determine whether or not the string is present
        return allowed.componentsSeparatedByString(c).count > 1
        
    }
    
    /*
     *  Retrieves an array of parts being added together and an array of parts
     *  being subtracted apart in the string.
     */
    func getAddedAndSubtractedParts(str : String) -> [[String]] {
        
        // The depth inside parentheses
        var depth : Int = 0
        
        // The current part being added to
        var currentPart : String = ""
        
        // An array of parts both added and subtracted
        var partsAdded : [String] = []
        var partsSubtracted : [String] = []
        
        // Track whether or not we are adding the current part
        var adding : Bool = true
        
        // Get the array of characters
        var characters: Array = Array(str)
        
        // Loop through every character
        for var charIndex : Int = 0; charIndex < count(str); charIndex++ {
            
            // Get the character at the index
            var char : String = String(characters[charIndex])
            
            // If this is the first part and the character is subtraction
            if charIndex == 0 && char == "-" {
                
                // Append the character to the string
                currentPart += char
                
                // Continue past this character
                continue
                
            }
            
            // If we are entering parentheses
            if char == "(" {
                
                // Add the character to the string
                currentPart += char
                
                // Increase the depth
                depth++
                
            // If this is closing a set of parentheses
            } else if char == ")" {
                
                // Add the character
                currentPart += char
                
                // Decrease the depth
                depth--
                
            // If the character is an operation at the root level
            } else if (char == "+" || char == "-") && depth == 0 {
                
                // If there is content in the current part
                if count(currentPart) > 0 {
                    
                    // If we are adding this part
                    if adding {
                        
                        // Add the part to the addition list
                        partsAdded.append(currentPart)
                        
                    } else {
                        
                        // Add the part to the subtraction list
                        partsSubtracted.append(currentPart)
                        
                    }
                    
                    // Clear the old part
                    currentPart = ""
                    
                }
                
                // Are we adding or subtracting the next part
                adding = (char == "+")
                
            } else {
                
                // Add the character
                currentPart += char
                
            }
            
        }
        
        // If we have unhandled leftover parts
        if count(currentPart) > 0 {
            
            // If it is being added
            if adding {
                
                // Append it to the addition list
                partsAdded.append(currentPart)
                
            // If it is being subtracted
            } else {
                
                // Append it to the subtraction list
                partsSubtracted.append(currentPart)
                
            }
            
        }
        
        // Return the two arrays of addition and subtraction
        return [partsAdded, partsSubtracted]
        
    }
    
    /*
     *  Retrieves the value of the function at the input
     *  value 'x'
     */
    func getValueAtX(x: Float) -> Float {
        
        // Pass the call onto the true expression
        return self.trueExpression.getValueAtX(x)
        
    }
    
    /*
     *  Retrieves the name of this function
     */
    func getName() -> String {
        
        // Pass the call onto the true expression
        return self.trueExpression.getName()
        
    }
    
}

/*
let FUNC_SIN : (x: Float) -> Float = {
    (x: Float) in
    return sinf(x)
}
*/

/*
 *  The special function class handles an expression and evaluates it
 *  through the provided special function name.
 */
class GXSpecialFunction : GXMathExpression {
    
    // The name of the function
    private var name : String = ""
    
    // The expression on the inside of the function
    private var inside : GXMathExpression
    
    // The block used to evaluate the function
    private var evalBlock : (x: Float) -> Float
    
    /*
     *  Initializes a special function expression with the name of the special
     *  function and the expression on the inside
     */
    init(name : String, inside: GXMathExpression = GXVariableExpression()) {
        
        // Save the name of the function
        self.name = name
        
        // Save the inside contents of the function
        self.inside = inside
        
        // Find the closure used to evaluate the function given
        // the provided name
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
    
    /*
     *  Calculates the value of the function at the value 'x'
     */
    func getValueAtX(x: Float) -> Float {
        
        // Calculate the value of the inner part
        var innerX : Float = self.inside.getValueAtX(x)
        
        // Run the inner value through the function
        return self.evalBlock(x: innerX)
        
    }
    
    /*
     *  Returns the name of the function call
     */
    func getName() -> String {
        
        // Return the name of the function and the name of the inside expression
        return self.name + " ( " + self.inside.getName() + " ) "
        
    }
    
}

/*
 *  The variable expression represents an 'x' inside the function
 */
class GXVariableExpression : GXMathExpression {
    
    /*
     *  Calculates the value of the variable 'x' at the 
     *  input value of 'x'
     */
    func getValueAtX(x: Float) -> Float {
        
        // Return the x-value itself
        return x
        
    }
    
    /*
     *  Retrieves the name of the variable
     */
    func getName() -> String {
        
        // Simply return an 'x'
        return "x"
    }
    
}

/*
 *  The time variable expression represents a value that changes with time
 */
class GXTimeVariableExpression : GXMathExpression {
    
    /*
     *  Calculates the value of the time
     */
    func getValueAtX(x: Float) -> Float {
        
        // Return a floating point value of the current time
        return Float(CACurrentMediaTime())
        
    }
    
    /*
     *  Retrieves the name of the time variable
     */
    func getName() -> String {
        
        // Return a 't' for 'time'
        return "t"
    }
    
}

/*
 *  The math operation type enumerable defines all of the basic operations possible
 *  in the parser.
 */
enum GXMathOperationType {
    
    // Define all the operation cases
    case Add
    case Subtract
    case Multiply
    case Divide
    case PlusOrMinus
    case Exponent
    
    /*
     *  Performs the operation on the provided left- and right-hand arguments. Returns
     *  an array of the outputs
     */
    func perform(a : Float, b : Float) -> [Float] {
        
        // Define an array for the output values
        var values: [Float] = []
        
        // Switch through the possible operations
        switch self {
            
            // If this is the addition operation
            case .Add:
                
                // Append the sum of the numbers
                values.append(a + b)
            
            // If this is the subtraction operation
            case .Subtract:
                
                // Append the difference of the numbers
                values.append(a - b)
            
            // If this is the multiplication operation
            case .Multiply:
                
                // Append the product of the numbers
                values.append(a * b)
            
            // If this is the division operation
            case .Divide:
            
                // Append the quotient of the numbers
                values.append(a / b)
            
            // If this is the plus/minus operation
            case .PlusOrMinus:
            
                // Append both the sum and the difference
                values.append(a + b)
                values.append(a - b)
            
            // If this is the exponent operation
            case .Exponent:
                
                // Append the power value
                values.append(pow(a, b))
        }
        
        // Return the array of values
        return values
        
    }
    
    /*
     *  Retrieves the symbol representing this operation
     */
    func getSymbol() -> String {
        
        // Switch through the types of operations
        switch self {
            
            // If this is the addition operation
            case .Add:
                
                // Return the addition symbol
                return "+"
            
            // If this is the subtraction operation
            case .Subtract:
                
                // Return the subtraction symbol
                return "-"
            
            // If this is the multiplication operation
            case .Multiply:
                
                // Return the multiplication symbol
                return "*"
        
            // If this is the division operation
            case .Divide:
                
                // Return the division symbol
                return "/"
            
            // If this is the plus/minus operation
            case .PlusOrMinus:
                
                // Return the plus/minus symbol
                return "(+/-)"
            
            // If this is the exponential operation
            case .Exponent:
                
                // Return the exponent symbol
                return "^"
        }
    }
    
}

/*
 *  Below we define closures for the typical operations. We do this because for each
 *  input value to the function, we will need to perform the operation. Doing comparison
 *  for each input to determine which operation to use will cause a performance decrease,
 *  so we instead store a pointer to the operation closure after doing a single comparison
 *  upon initialization. Then, for each input we just run the input through the closure.
 */

// Define a multiplication closure
let OP_MULT : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a * b
}

// Define an addition closure
let OP_ADD : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a + b
}

// Define a subtraction closure
let OP_SUB : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a - b
}

// Define a division closure
let OP_DIV : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return a / b
}

// Define an exponential operator
let OP_POW : (a: Float, b: Float) -> Float = {
    (a: Float, b: Float) in
    return powf(a, b)
}

/*
 *  The math operation expression is initialized with a left hand side and a right hand
 *  side and a provided operation to evaluate on the two.
 */
class GXMathOperation : GXMathExpression {
    
    // The type of operation to perform on the operands
    private var operationType : GXMathOperationType
    
    // The left- and right-hand operands
    private var expressionA : GXMathExpression
    private var expressionB : GXMathExpression
    
    // The block used to perform the operation
    private var operationBlock : ((a: Float, b: Float) -> Float)?
    
    // Initializer for the math operation
    init(expressionA : GXMathExpression, expressionB : GXMathExpression, operation : GXMathOperationType) {
        
        // Store the type of operation this is
        self.operationType = operation
        
        // Store the left and right expressions
        self.expressionA = expressionA
        self.expressionB = expressionB
        
        // Check for the type of operation and find the appropriate
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
        
            // If the operation cannot find a match, make our own closure
            self.operationBlock = {
                (a: Float, b: Float) in
                
                // Perform the operation that fits the operation type.
                // This causes a performance hit, but is not a common issue.
                return self.operationType.perform(a, b: b)[0]
            }
            
        }
        
    }
    
    /*
     *  Retrieves the value of the operation at the input 'x'
     */
    func getValueAtX(x : Float) -> Float {
        
        // Calculate the values of the two operands
        var valueA : Float = self.expressionA.getValueAtX(x)
        var valueB : Float = self.expressionB.getValueAtX(x)
        
        // Run the operands through the operation closure
        return self.operationBlock!(a: valueA, b: valueB)
        
    }
    
    /*
     *  Constructs the name of the operation
     */
    func getName() -> String {
        
        // Append the names of the two operands with the operation in the middle
        return "(" + self.expressionA.getName() + " " + self.operationType.getSymbol() + " " + self.expressionB.getName() + ")"
        
    }
    
}