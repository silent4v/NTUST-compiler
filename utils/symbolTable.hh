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
#define INDEX(key) std::get<2>(key)
#define INDEX_S(key)                    \
  ([&]() -> std::string {               \
    std::string s = "";                 \
    s += ((char)std::get<2>(key)+48);   \
    return s;                           \
  })()                                  \

#define VALUE(key) std::get<3>(key)

#define DEBUG(msg)                                                             \
  {                                                                            \
    if (SymbolTable::debug_mode)                                               \
      std::cout << (msg) << std::endl;                                         \
  }
#define AS_STR(idx) (char)(idx+48)
using Symbol = std::tuple<std::string, uint8_t, short, std::string>;
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

  Symbol lookup(std::string name, bool withError = true);

  Symbol insert(std::string name, uint8_t type, ushort idx = -1, std::string value = "\r");

  std::vector<u_int8_t> formalArgs(std::string fn);

  /* variable store in currently accessed */
  Table symbols;

  /* Current scope name */
  std::string scopeName;

  bool isGlobal();

  void print();

private:
  /* point to the parent of currently accessed block */
  std::weak_ptr<SymbolTable> parent_;

  /* branchs of self node, */
  std::vector<std::shared_ptr<SymbolTable>> children_;
};

#endif /* _SYMBOL_TABLE_H_ */