# What is GraphX
GraphX is a framework for parsing strings of mathematical expressions and 
converting them to functions that can be evaluated.

# Example: Creating a Function

```swift
// Define a string for the math expression
var expression: String = "x^3+3x^2-4"

// Create a function from the expression
var function: GXFunction = GXFunction(expression: expression)

// Get the value of the function at some input x
var value: Float = function.getValueAtX(10.0)

// Output some values of the function
println("f(0) => \(function.getValueAtX(0.0))")
println("f(2) => \(function.getValueAtX(2.0))")
println("f(4) => \(function.getValueAtX(4.0))")
println("f(6) => \(function.getValueAtX(6.0))")
```

# The To-Do List

~~The most important to-do right now is documenting the code. The number of comments
in the code is simply sad.~~


