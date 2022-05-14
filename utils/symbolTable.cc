#include "symbolTable.hh"
#include "type.hh"

std::shared_ptr<SymbolTable> SymbolTable::cursor = nullptr;
bool SymbolTable::debug_mode = false;

SymbolTable::SymbolTable() {
  this->parent_ = nullptr;
  this->children_.reserve(20);
  this->scopeName = "__GLOBAL__";
}

void SymbolTable::enableDebug() { SymbolTable::debug_mode = true; }

void SymbolTable::create(std::string className) {
  auto globalScope = std::make_shared<SymbolTable>();
  globalScope->scopeName = className;
  SymbolTable::cursor = globalScope;

  DEBUG("Application: " + symbol(className))
}

void SymbolTable::enter(std::string scopeName) {
  auto scope = std::make_shared<SymbolTable>();
  scope->scopeName = scopeName;
  scope->parent_ = this->shared_from_this();
  this->children_.push_back(scope);
  SymbolTable::cursor = scope;
  DEBUG(symbol(SymbolTable::cursor->scopeName) + " --> " + symbol(scopeName))
}

void SymbolTable::exit() {
  auto prevScopeName = SymbolTable::cursor->scopeName;
  if (SymbolTable::cursor->parent_ != nullptr) {
    SymbolTable::cursor = SymbolTable::cursor->parent_;
  }
  DEBUG(symbol(prevScopeName) + " --> " + symbol(SymbolTable::cursor->scopeName))
}

bool SymbolTable::exists(std::string name) {
  bool find = false;
  auto cursor = SymbolTable::cursor;
  while (cursor->parent_ != nullptr) {
    auto currCheckTable = SymbolTable::cursor->symbols_;
    auto result = std::any_of(currCheckTable.cbegin(), currCheckTable.cend(),
                              [&name](auto &var) { return NAME(var) == name; });
    if (result) {
      find = true;
      DEBUG(red(name) + " exists @" + symbol(SymbolTable::cursor->scopeName))
    }
    cursor = cursor->parent_;
  }
}

Symbol SymbolTable::lookup(std::string name) {
  auto cursor = SymbolTable::cursor;
  while (SymbolTable::cursor->parent_ != nullptr) {
    auto currCheckTable = SymbolTable::cursor->symbols_;
    auto result =
        std::find_if(currCheckTable.cbegin(), currCheckTable.cend(),
                     [&name](auto &var) { return NAME(var) == name; });
    if (result != currCheckTable.cend()) {
      return *result;
    } else {
      cursor = cursor->parent_;
    }
  }
  std::cout << red("Fatal Error:") << symbol(name) << " not found";
  std::exit(-1);
}

Symbol SymbolTable::insert(std::string name, uint8_t type, std::string ctx) {
  auto &scope = SymbolTable::cursor;
  if (scope->exists(name)) {
    std::cout << red("Fatal Error:") << symbol(name) << " already exists";
    std::exit(-1);
  }
  auto tuple = std::make_tuple(name, type, ctx);
  scope->symbols_.push_back(tuple);
  DEBUG("[INSERT] " + symbol(name) + "<" + typeinfo(type) + ">")
  return tuple;
}
