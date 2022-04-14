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

void SymbolTable::dump() const
{
  std::cout << cyan("DUMP") << " Symbol Table: \n";
  for(auto&& symbol : this->layer_) 
  {
    std::cout << std::setfill(' ') << std::setw(15+10) <<id(symbol.name);
    std::cout << "[" << keyword(symbol.type) << "]"
              << "\n";
  }
}