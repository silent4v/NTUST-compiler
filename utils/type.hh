#ifndef _TYPE_H_
#define _TYPE_H_

#include <cstdint>
#include <cstring>

#include <fstream>
#include <iostream>
#include <iomanip>
#include <utility>
#include <algorithm>

#define T_VOID    0b00000000
#define T_BOOL    0b00000001
#define T_INT     0b00000010
#define T_FLOAT   0b00000100
#define T_STRING  0b00001000
#define T_CONST   0b00010000
#define T_ARRAY   0b00100000
#define T_FN      0b01000000


const char* typeinfo(uint8_t typeCode);
const char* typeinfo(std::pair<std::string, uint8_t> id);

struct YYType
{
  int state;
  uint8_t type;
  std::pair<std::string, uint8_t> context;
};


#define YYSTYPE YYType
#endif /* _TYPE_H_ */
