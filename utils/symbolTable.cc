#include "symbolTable.hh"

SymbolTable::SymbolTable()
{
  this->currentLayer_ = 0;
}

void SymbolTable::create()
{
  
}

void SymbolTable::lookup()
{
  
}

void SymbolTable::insert(const char* name, std::string type)
{
  std::string temp = std::string(name);
  Symbol symbol = {
    name,
    type,
    0
  };
  this->layer_.push_back(symbol);
}

void SymbolTable::dump()
{
  std::cout << cyan("DUMP") << " Symbol Table: \n";
  for(auto&& symbol : this->layer_) 
  {
    std::cout << id(std::move(symbol.name)) 
              << "[" 
              << keyword(std::move(symbol.type))
              << "]" 
               << "\n";
  }
}