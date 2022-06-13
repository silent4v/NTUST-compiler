#ifndef _JAVAC_H_
#define _JAVAC_H_

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <sstream>
#include <map>
#include "symbolTable.hh"

class CodeGenerate {
public:
  CodeGenerate();
  ~CodeGenerate();
  void put(std::string content);
  
  std::string initial(std::string cName);
  std::string funcDecl(std::string fnName, std::string type, std::string args, std::string content = "@func_body");
  std::string getVar(Symbol s);
  std::string setVar(Symbol s);
  std::string getLabel();
  void flush(std::string& buf);
  std::map<std::string, std::string> constMap;

  ushort localCount;
  ushort labelCount;
  std::fstream fs;
  std::string codeBuffer;
  std::string cName;
};

#endif /* _JAVAC_H_ */