/*
 * Example with Functions 
 */

/* Example with Functions */
class example {

  // constants
  val a = -5

  // variables
  var c : int

  // function declaration
  fun add (a: int, b: int) : int {
    return a+b
  }
  
  // main statements
  fun main() {
    c = add("ta", -1.25)
    if (c < 10e5)
      print -c
    else
      print c
    println ("Hello""World")
  }
}