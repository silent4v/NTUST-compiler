#ifndef _COLORIZED_H_
#define _COLORIZED_H_

#include <iostream>
#include <functional>
#include <sstream>
#include <string>

#define RED     "\033[0;31m"
#define GREEN   "\033[0;32m"
#define YELLOW  "\033[0;33m"
#define BLUE    "\033[0;34m"
#define PURPLE  "\033[0;35m"
#define CYAN    "\033[0;36m"
#define RESET   "\033[0;37m"


template<typename T>
std::function<std::string(T&& msg)> colorized(const char* ColorCode);

void reset();

using TPrintFunction = decltype(colorized<std::string>(RED));

/* Define Colorful Print function */
extern TPrintFunction red;
extern TPrintFunction green;
extern TPrintFunction yellow;
extern TPrintFunction blue;
extern TPrintFunction purple;
extern TPrintFunction cyan;

/* Special color for token-util */
extern TPrintFunction id;
extern TPrintFunction symbol;
extern TPrintFunction keyword;
extern TPrintFunction operators;
extern TPrintFunction comment;

#endif /* _COLORIZED_H_ */
