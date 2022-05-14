#include "symbolTable.hh"
#include "type.hh"

inline void printv(std::vector<Symbol> &vec) {
  if (SymbolTable::debug_mode) {
    std::string sep = "";
    std::cout << "table: ";
    for (auto &sb : vec) {
      std::cout << sep << NAME(sb);
      sep = ", ";
    }
    std::cout << std::endl;
  }
}

std::shared_ptr<SymbolTable> SymbolTable::root = nullptr;
std::shared_ptr<SymbolTable> SymbolTable::cursor = nullptr;
bool SymbolTable::debug_mode = false;

SymbolTable::SymbolTable() {
  this->parent_.reset();
  this->children_.reserve(20);
  this->scopeName = "__GLOBAL__";
}

void SymbolTable::enableDebug() { SymbolTable::debug_mode = true; }

void SymbolTable::create(std::string className) {
  auto globalScope = std::make_shared<SymbolTable>();
  globalScope->scopeName = className;
  SymbolTable::cursor = globalScope;
  SymbolTable::root = globalScope;
  DEBUG("Application: " + symbol(className))
}

void SymbolTable::enter(std::string scopeName) {
  auto scope = std::make_shared<SymbolTable>();
  auto currScope = SymbolTable::cursor->scopeName;
  scope->scopeName = currScope + "." + scopeName;
  scope->parent_ = SymbolTable::cursor;
  SymbolTable::cursor->children_.push_back(scope);
  printv(SymbolTable::cursor->symbols);
  SymbolTable::cursor = scope;
  DEBUG(green("[Enter] ") + symbol(currScope) + " --> " +
        symbol(SymbolTable::cursor->scopeName))
}

void SymbolTable::exit() {
  auto prevScopeName = SymbolTable::cursor->scopeName;
  if (SymbolTable::cursor->parent_.lock() != nullptr) {
    SymbolTable::cursor = SymbolTable::cursor->parent_.lock();
  }
  DEBUG(red("[Exit] ") + symbol(prevScopeName) + " --> " +
        symbol(SymbolTable::cursor->scopeName))
}

bool SymbolTable::exists(std::string name) {
  bool find = false;
  auto cursor = SymbolTable::cursor;
  while (cursor != SymbolTable::root) {
    auto currCheckTable = cursor->symbols;
    auto result = std::any_of(currCheckTable.cbegin(), currCheckTable.cend(),
                              [&name](auto &var) { return NAME(var) == name; });
    if (result) {
      find = true;
      DEBUG(red(name) + " exists @" + symbol(SymbolTable::cursor->scopeName))
    }
    cursor = cursor->parent_.lock();
  }
  return find;
}

Symbol SymbolTable::lookup(std::string name) {
  auto cursor = SymbolTable::cursor;
  while (true) {
    auto currCheckTable = cursor->symbols;
    DEBUG("--> lookup: " + name + "@" + keyword(cursor->scopeName))
    auto result =
        std::find_if(currCheckTable.cbegin(), currCheckTable.cend(),
                     [&name](auto &var) { return NAME(var) == name; });
    if (result != currCheckTable.cend()) {
      return *result;
    } else {
      if (cursor == SymbolTable::root) {
        break;
      }
      cursor = cursor->parent_.lock();
    }
  }

  std::cout << red("Fatal Error: ") << symbol(name) << " not found\n";
  printv(cursor->symbols);
  std::exit(-1);
}

Symbol SymbolTable::insert(std::string name, uint8_t type, std::string ctx) {
  auto &scope = SymbolTable::cursor;
  if (scope->exists(name)) {
    std::cout << red("Fatal Error: ") << symbol(name) << " already exists";
    std::exit(-1);
  }
  auto tuple = std::make_tuple(name, type, ctx);
  scope->symbols.push_back(tuple);
  DEBUG("[INSERT] " + symbol(name) + "<" + typeinfo(type) + ">")
  return tuple;
}

void SymbolTable::print() {
  auto rootTable = SymbolTable::root;
  std::deque<decltype(rootTable)> logQueue = {rootTable};

  while (logQueue.size() > 0) {
    auto table = logQueue.front();
    std::cout << blue("[" + table->scopeName + "]") << "\n";
    for (auto &v : table->symbols) {
      std::cout << NAME(v) << "<" << keyword(typeinfo(TYPE(v))) << ">\n";
    }

    for (auto &subTable : table->children_) {
      logQueue.push_back(subTable);
    }
    logQueue.pop_front();
  }
}
