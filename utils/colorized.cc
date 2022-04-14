#include "colorized.hh"

template<typename T>
std::function<std::string(const T msg)> colorized(const char* ColorCode)
{
  return [ColorCode](const T message) -> T {
    std::stringstream ss;
    ss << ColorCode << message << RESET;
    return ss.str();
  };
}

void reset() {
  std::cout << RESET;
}

TPrintFunction red    = colorized<std::string>(RED);
TPrintFunction green  = colorized<std::string>(GREEN);
TPrintFunction yellow = colorized<std::string>(YELLOW);
TPrintFunction blue   = colorized<std::string>(BLUE);
TPrintFunction purple = colorized<std::string>(PURPLE);
TPrintFunction cyan   = colorized<std::string>(CYAN);

TPrintFunction id = red;
TPrintFunction symbol = blue;
TPrintFunction keyword = green;
TPrintFunction operators = purple;
TPrintFunction comment = yellow;