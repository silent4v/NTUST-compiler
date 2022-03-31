#ifndef _COLORIZED_H_
#define _COLORIZED_H_
#include <iostream>
#include <functional>
#include <sstream>

#define RED     "\033[0;31m"
#define GREEN   "\033[0;32m"
#define YELLOW  "\033[0;33m"
#define BLUE    "\033[0;34m"
#define PURPLE  "\033[0;35m"
#define CYAN    "\033[0;36m"
#define RESET   "\033[0;37m"

template<typename T>
std::function<std::string(T&& msg)> colorized(const char* ColorCode) 
{
  return [ColorCode](T&& message) -> T {
    std::stringstream ss;
    ss << ColorCode << message << RESET;
    return ss.str();
  };
}

void reset() {
  std::cout << RESET;
}

auto red = colorized<std::string>(RED);
auto green = colorized<std::string>(GREEN);
auto yellow = colorized<std::string>(YELLOW);
auto blue = colorized<std::string>(BLUE);
auto purple = colorized<std::string>(PURPLE);
auto cyan = colorized<std::string>(CYAN);

auto id = red;
auto symbol = blue;
auto keyword = green;
auto operators = purple;
auto comment = yellow;
#endif /* _COLORIZED_H_ */
