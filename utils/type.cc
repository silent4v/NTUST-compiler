#include "type.hh"

const char* typeinfo(uint8_t typeCode)
{
  switch( typeCode )
  {
    case T_BOOL: return "bool";
    case T_INT: return "integer";
    case T_FLOAT: return "float";
    case T_STRING: return "string";
    default: return "unknown_type";
  }
}

const char* typeinfo(std::pair<std::string, uint8_t> id)
{
  switch( id.second )
  {
    case T_BOOL: return "bool";
    case T_INT: return "integer";
    case T_FLOAT: return "float";
    case T_STRING: return "string";
    default: return "void(id)";
  }
}