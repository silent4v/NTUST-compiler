#ifndef _SYMBOL_TABLE_H_
#define _SYMBOL_TABLE_H_

#include "colorized.hh"
#include "type.hh"
#include <iomanip>
#include <iostream>
#include <memory>
#include <utility>
#include <vector>
#include <deque>

#define NAME(key) std::get<0>(key)
#define TYPE(key) std::get<1>(key)
#define VALUE(key) std::get<2>(key)
#define DEBUG(msg)                                                             \
  {                                                                            \
    if (SymbolTable::debug_mode)                                               \
      std::cout << (msg) << std::endl;                                         \
  }

using Symbol = std::tuple<std::string, uint8_t, std::string>;
using Table = std::vector<Symbol>;

class SymbolTable : public std::enable_shared_from_this<SymbolTable> {
public:
  SymbolTable();

  static std::shared_ptr<SymbolTable> root;

  /* Always point to the currently accessed block */
  static std::shared_ptr<SymbolTable> cursor;

  /* if true, print debug info */
  static bool debug_mode;

  /* set `debug_mode_` flag true */
  void enableDebug();

  /* when program state, generate root scope */
  void create(std::string className = "_CLASS_ENTRY_");

  void enter(std::string scopeName);

  void exit();

  bool exists(std::string name);

  Symbol lookup(std::string name);

  Symbol insert(std::string name, uint8_t type, std::string ctx = "\r\r");

  /* variable store in currently accessed */
  Table symbols;

  /* Current scope name */
  std::string scopeName;

  void print();

private:
  /* point to the parent of currently accessed block */
  std::weak_ptr<SymbolTable> parent_;

  /* branchs of self node, */
  std::vector<std::shared_ptr<SymbolTable>> children_;
};

#endif /* _SYMBOL_TABLE_H_ */