# GraphX
iOS graphing calculator app and math expression parsing framework.

# What is GraphX
GraphX is a framework for parsing strings of mathematical expressions and 
converting them to functions that can be evaluated.

# Example: Creating a Function

```
// Define a string for the math expression
var expression: String = "x^3+3x^2-4"

// Create a function from the expression
var function: GXFunction = GXFunction(expression: expression)

// Output some values of the function
println("f(0) => \(function.getValueAtX(0.0)")
println("f(2) => \(function.getValueAtX(2.0)")
println("f(4) => \(function.getValueAtX(4.0)")
println("f(6) => \(function.getValueAtX(6.0)")

```

# Example: Drawing the Graph

This can also be used to draw a graph on the screen, using the GXGraphView class,
as shown below

```
/*
 *  Inside the viewDidLoad method on a UIViewController
 */
override func viewDidLoad() -> Void {

    // Create a view for the graph
    var graphView: GXGraphView = GXGraphView(frame: self.view.bounds)
  
    // Define a string for the math expression
    var expression: String = "x^3+3x^2-4"

    // Create a function from the expression
    var function: GXFunction = GXFunction(expression: expression)
    
    // Add the function to the view
    graphView.addFunction(function)
    
}
```

# The To-Do List

The most important to-do right now is documenting the code. The number of comments
in the code is simply sad.
