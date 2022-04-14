#ifndef _SYMBOL_TABLE_H_
#define _SYMBOL_TABLE_H_

#include <map>
#include <deque>
#include <iostream>
#include <iomanip>
#include <utility>
#include "colorized.hh"

struct Symbol
{
  std::string name;
  std::string type;
  int tier;
};

class SymbolTable
{
public:
  SymbolTable();
  void create();
  void lookup();
  void insert(const char* name, std::string type);
  void dump() const;
private:
  std::deque<Symbol> layer_;
  int  currentLayer_;
};

#endif /* _SYMBOL_TABLE_H_ */