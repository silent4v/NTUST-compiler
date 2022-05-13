#include "symbolTable.hh"
#include "type.hh"

SymbolTable::SymbolTable() { this->layerIndex_ = 0; }
void SymbolTable::enableDebug() { this->debug_ = true; }

void SymbolTable::create(std::string className) {
  this->layerIndex_ = 0;
  std::pair<std::string, Table> globalScope = {className, {}};
  this->layer_.push_back(globalScope);
  if (this->debug_)
    std::cout << "CLASS " << symbol("[" + className + "]") << "\n";
}

void SymbolTable::next(std::string scopeName) {
  std::pair<std::string, Table> scope = {scopeName, {}};
  auto from = this->layer_[this->layerIndex_].first;
  this->layer_.push_back(scope);
  this->layerIndex_++;
  auto to = this->layer_[this->layerIndex_].first;
  if (this->debug_)
    std::cout << "\nScope [" << symbol(from) << " -> " << symbol(to) << "]\n";
}

void SymbolTable::exit() {
  auto from = this->layer_[this->layerIndex_].first;
  this->layer_.pop_back();
  this->layerIndex_--;
  auto to = this->layer_[this->layerIndex_].first;
  if (this->debug_)
    std::cout << "\nScope [" << symbol(from) << " -> " << symbol(to) << "]\n";
}

void SymbolTable::insert(std::string name, uint8_t type) {
  auto &scope = this->currentScope_();
  if (std::any_of(scope.begin(), scope.end(),
                  [&name](auto &var) { return var.first == name; })) {
    std::cout << red("Fatal Error: ") << "`" + name + "`"
              << " has been declared.\n";
    std::exit(-1);
  }

  auto variable = std::make_pair(name, type);

  scope.push_back(variable);
  if (type & T_FN) {
    if (this->debug_) {
      std::cout << "[Function] " << variable.first << ": "
                << keyword(typeinfo(variable.second)) << "\n";
    }
  } else {
    std::cout << "[insert] " << variable.first << "<"
              << keyword(typeinfo(variable.second)) << ">\n";
  }
}

Pair SymbolTable::lookup(std::string name) {
  auto &scope = this->currentScope_();
  auto iter = std::find_if(scope.cbegin(), scope.cend(),
                           [&name](auto &var) { return var.first == name; });

  if (iter == scope.end()) {
    std::cout << red("Fatal Error: ") << "`" + name + "`"
              << " not found.\n";
    std::exit(-1);
  }

  return *iter;
}

Table &SymbolTable::currentScope_() {
  return this->layer_[this->layerIndex_].second;
}

void SymbolTable::dump() const {}