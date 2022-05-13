class Test
{
  // constant declare
  val s:string = "Hey There"
  val i = -25
  val f = 3.14
  val b:bool = true

  // mutable declare
  var s1: string
  var i2 = 10
  var d3: float
  var b4: bool = false

  // function declare
  fun main () {

    // statement
    sum = 0
    arr[index] = 0
    print test
    print (test)
    print (10 + 20)
    println test
    println (test)
    println (10 + 20)
    read sum
    read sum[10]

    // while-loop
    while (index <= n) {
      sum = sum + index
      index = index + 1
      sum = 0
      arr[index] = 0
      print test
      print (test)
      print (10 + 20)
      println test
      println (test)
      println (10 + 20)
      read sum
      read sum[10]
      // if in while-loop
      if (true)
        println (sum)
    }

    // while-loop simple statement
    while (index <= n) print (test)

    // for-loop
    for (index in 0 .. 10) {
      sum = sum + index
      index = index + 1
      sum = 0
      arr[index] = 0
      print test
      print (test)
      print (10 + 20)
      println test
      println (test)
      println (10 + 20)
      read sum
      read sum[10]
      // if in for-loop
      if (true)
        println (sum)
    }

    // for-loop simple statement
    for (index in 0 .. 10)
      print (index)
    
    println (sum)
  }

  // if simple-statement
  if (true)
    println (sum)

  // if block-statement
  if (true) {
    sum = sum + index
    index = index + 1
    sum = 0
    arr[index] = 0
    print test
    print (test)
    print (10 + 20)
    println test
    println (test)
    println (10 + 20)
    read sum
    read sum[10]
  }

  // if-else simple-statement
  if(false) 
    sum = sum + index
  else
    sum = sum + index

  // if block-statement
  if(false) {
    println test
    println (test)
  } else {
    println test
    println (test)
  }

  var a: integer [10] // an array of 10 integer elements
  var b: boolean [5] // an array of 6 boolean elements
  var f: float [100] // an array of 100 float elements
  a = 1 + 2 * 3 + 4 + sigma(1,2,3)
}