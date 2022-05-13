/* Sigma.kt
 *
 * Compute sum = 1 + 2 + ... + n
 */

class Sigma
{
  // constants and variables
  val n = "test"
  var sum: int
  var index: int

  fun main () {
    sum = 0
    index = 0
    
    while (index <= n) {
      sum = sum + index + 1
      index = index + 1
    }
    print ("The sum is ")
    println (sum)
  }
}