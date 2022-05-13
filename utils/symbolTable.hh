#ifndef _SYMBOL_TABLE_H_
#define _SYMBOL_TABLE_H_

#include <map>
#include <vector>
#include <iostream>
#include <iomanip>
#include <utility>
#include "colorized.hh"
#include "type.hh"

using Table = std::vector<Pair>;
using Layer = std::pair<std::string, Table>;
class SymbolTable
{
public:
  SymbolTable();
  void enableDebug();
  void create(std::string className = "_GLOBAL_");
  void next(std::string scopeName);
  void exit();
  void insert(std::string name, uint8_t type);
  Pair lookup(std::string name);
  void insert(const char *name, std::string type);
  void dump() const;

private:
  Table &currentScope_();
  std::vector<Layer> layer_;
  int layerIndex_;
  bool debug_;
};

#endif /* _SYMBOL_TABLE_H_ */