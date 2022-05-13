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

void SymbolTable::flash() {
  auto snapshot = this->layer_[this->layerIndex_];
  std::cout << this->layerIndex_ << ", " << snapshot.second.size() << "\n";
  this->GLOBAL_.push_back(
      std::make_pair(this->layerIndex_, this->currentScope_()));
  this->currentScope_().clear();
}

void SymbolTable::next(std::string scopeName) {
  std::pair<std::string, Table> scope = {scopeName, {}};
  auto from = this->layer_[this->layerIndex_].first;
  this->flash();
  this->layer_.push_back(scope);
  this->layerIndex_++;
  auto to = this->layer_[this->layerIndex_].first;
  if (this->debug_)
    std::cout << "\nScope [" << symbol(from) << " -> " << symbol(to) << "]\n";
}

void SymbolTable::exit() {
  auto from = this->layer_[this->layerIndex_].first;
  this->flash();
  this->layer_.pop_back();
  this->layerIndex_--;
  auto& to = this->layer_[this->layerIndex_].first;
  to.clear();
  if (this->debug_)
    std::cout << "\nScope [" << symbol(from) << " -> " << symbol(to) << "]\n";
}

void SymbolTable::insert(std::string name, uint8_t type, std::string ctx) {
  auto &scope = this->currentScope_();
  if (std::any_of(scope.begin(), scope.end(),
                  [&name](auto &var) { return NAME(var) == name; })) {
    std::cout << red("Fatal Error: ") << "`" + name + "`"
              << " has been declared.\n";
    std::exit(-1);
  }

  auto variable = std::make_tuple(name, type, ctx);

  scope.push_back(variable);
  if (this->debug_) {
    if (type & T_FN) {
      std::cout << "[Function] " << NAME(variable) << ": "
                << keyword(typeinfo(TYPE(variable))) << "\n";
    } else if (type & T_ARG) {
      std::cout << "[define-arg] " << NAME(variable) << "<"
                << keyword(typeinfo(TYPE(variable))) << ">\n";
    } else if (type & T_ARRAY) {
      std::cout << "[insert] " << NAME(variable) << "<"
                << keyword(typeinfo(TYPE(variable))) << "[]>\n";
    } else {
      std::cout << "[insert] " << NAME(variable) << "<"
                << keyword(typeinfo(TYPE(variable))) << ">\n";
    }
  }
}

State SymbolTable::lookup(std::string name) {
  auto &scope = this->currentScope_();
  auto iter = std::find_if(scope.cbegin(), scope.cend(),
                           [&name](auto &var) { return NAME(var) == name; });

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

void SymbolTable::dump() const {
  auto setIndent = [](int n) {
    std::string space = "";
    for (int i = 0; i < n; ++i) {
      space += "  ";
    }
    return space;
  };

  for (auto scope : this->GLOBAL_) {
    auto indent = setIndent(scope.first);
    auto table = scope.second;
    std::cout << cyan("Layer: ") << "\n";
    for (auto token : table) {
      std::cout << indent << NAME(token) << ":" << typeinfo(TYPE(token))
                << " = " << VALUE(token) << "\n";
    }
  }
}