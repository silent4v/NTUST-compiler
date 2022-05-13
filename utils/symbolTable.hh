#ifndef _SYMBOL_TABLE_H_
#define _SYMBOL_TABLE_H_

#include "colorized.hh"
#include "type.hh"
#include <iomanip>
#include <iostream>
#include <map>
#include <utility>
#include <vector>

#define NAME(key) std::get<0>(key)
#define TYPE(key) std::get<1>(key)
#define VALUE(key) std::get<2>(key)


using State = std::tuple<std::string, uint8_t, std::string>;
using Table = std::vector<State>;
using Layer = std::pair<std::string, Table>;
class SymbolTable {
public:
  SymbolTable();
  void enableDebug();
  void create(std::string className = "_GLOBAL_");
  void flash();
  void next(std::string scopeName);
  void exit();
  void insert(std::string name, uint8_t type, std::string ctx = "\r");
  State lookup(std::string name);
  void insert(const char *name, std::string type);
  void dump() const;

private:
  Table &currentScope_();
  std::vector<Layer> layer_;
  std::vector<std::pair<unsigned, Table>> GLOBAL_;
  int layerIndex_;
  bool debug_;
};

#endif /* _SYMBOL_TABLE_H_ */