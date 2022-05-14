#include "type.hh"
#include "colorized.hh"

std::string typeinfo(uint8_t typeCode) {
  std::string typeName = "";
  switch (typeCode & 0b00001111) {
  case T_BOOL:
    typeName = "bool";
    break;
  case T_INT:
    typeName = "int";
    break;
  case T_FLOAT:
    typeName = "float";
    break;
  case T_STRING:
    typeName = "string";
    break;
  default:
    typeName = "void";
    break;
  }

  if (typeCode & T_CONST)
    typeName = "const " + typeName;
  if (typeCode & T_ARRAY)
    typeName = typeName + "[]";
  if (typeCode & T_ARG)
    typeName = typeName + " :param";
  if (typeCode & T_FN)
    typeName = "Fn<" + typeName + ">";

  return typeName;
}

std::string typeinfo(std::pair<std::string, uint8_t> id) {
  std::string typeName = "";
  auto typeCode = id.second;
  switch (typeCode & 0b00001111) {
  case T_BOOL:
    typeName = "bool";
    break;
  case T_INT:
    typeName = "int";
    break;
  case T_FLOAT:
    typeName = "float";
    break;
  case T_STRING:
    typeName = "string";
    break;
  default:
    typeName = "void";
    break;
  }

  if (typeCode & T_CONST)
    typeName = "const " + typeName;
  if (typeCode & T_ARRAY)
    typeName = typeName + "[]";
  if (typeCode & T_ARG)
    typeName = typeName + " :param";
  if (typeCode & T_FN)
    typeName = "Fn<" + typeName + ">";

  return typeName;
}

void typeCheck(uint8_t t1, uint8_t t2) {
  if (t1 != t2) {
    std::cout << red("Error: ") << keyword(typeinfo(t1)) << " and "
              << keyword(typeinfo(t2)) << " not match\n";
    exit(-1);
  }
}

void typeCheck(Pair p1, Pair p2) {
  if (p1.second != p2.second) {
    std::cout << red("Error: ") << keyword(typeinfo(p1)) << " and "
              << keyword(typeinfo(p2)) << " not match\n";
    exit(-1);
  }
}