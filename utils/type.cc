#include "type.hh"
#include "colorized.hh"

const char* typeinfo(uint8_t typeCode)
{
  switch( typeCode & 0b00001111 )
  {
    case T_BOOL: return "bool";
    case T_INT: return "int";
    case T_FLOAT: return "float";
    case T_STRING: return "string";
    default: return "void";
  }
}

const char* typeinfo(std::pair<std::string, uint8_t> id)
{
  switch( id.second & 0b00001111 )
  {
    case T_BOOL: return "bool";
    case T_INT: return "int";
    case T_FLOAT: return "float";
    case T_STRING: return "string";
    default: return "void(id)";
  }
}

void typeCheck(uint8_t t1, uint8_t t2)
{
  if(t1 != t2)
  {
    std::cout << red("Error: ")
              << keyword(typeinfo(t1)) << " and " << keyword(typeinfo(t2))
              << " not match\n";
    exit(-1);
  }
}

void typeCheck(Pair p1, Pair p2)
{
  if(p1.second != p2.second)
  {
    std::cout << red("Error: ")
              << keyword(typeinfo(p1)) << " and " << keyword(typeinfo(p2))
              << " not match\n";
    exit(-1);
  }
}