/*
 * Example with Functions 
 */

/* Example with Functions */
class example {

  // constants
  val a = -5

  // variables
  var b = 10
  var c: int
  var d: int = 30
  var k = 40
  val j = 50

  // function declaration
  fun add (a: int, b: int) : int {
      var c: int = 40
      var d: int = 30
      return a + b + c + d + 10 + 20 + k + j
  }
  
  // main statements
  fun main() {
    c = add(a, 10)

    if (c > 10)
      print -c
    else
      print c


      

    println ("Hello World")
  }
}