#include "codeGenerate.hh"

CodeGenerate::CodeGenerate() {
  this->localCount = 0;
  this->labelCount = 0;
}

CodeGenerate::~CodeGenerate() {
  if(this->fs.is_open()) {
    fs.close();
  }
}

void CodeGenerate::put(std::string content) {
  this->codeBuffer = "\n" + this->codeBuffer + "\n" + content + "\n";
}

std::string CodeGenerate::initial(std::string cName) {
  auto filename = cName + ".class";
  this->cName = cName;
  std::stringstream ss;
  ss << "class " << cName << "\n"
     << "{\n"
     << "@global_decl\n"
     << "@class_body\n"
     << "}\n";

  return ss.str();
}

void CodeGenerate::flush(std::string &buf) {
  auto filename = cName + ".class";
  this->fs.open(filename, std::ios::out);
  if (!this->fs.is_open()) {
    std::cerr << "Open file failed.\n";
    std::exit(1);
  } else {
    this->fs << buf;
  }
  fs.close();
}

std::string CodeGenerate::funcDecl(std::string fnName, std::string type,
                                   std::string args, std::string content) {
  auto signature = type + " " + fnName + "(" + args + ")";
  std::stringstream ss;
  ss << "  method public static " << signature << "\n"
     << "  max_stack 15\n"
     << "  max_locals 15\n"
     << "  {\n"
     << content << "\n"
     << (type == "void" ? "return" : "ireturn") << "\n"
     << "  }\n";
  return ss.str();
}

std::string CodeGenerate::getVar(Symbol sb) {
  auto type = TYPE(sb) & TYPE_MASK;
  if (INDEX(sb) == -1) {
    return "getstatic " + typeinfo(type) + " " +
           (SymbolTable::root->scopeName + "." + NAME(sb)) + "\n";
  } else if (INDEX(sb) == -2) {
    return "sipush " + NAME(sb) + "\n";
  } else {
    return "iload " + INDEX_S(sb) + "\n";
  }
}

std::string CodeGenerate::setVar(Symbol sb) {
  auto type = TYPE(sb) & TYPE_MASK;
  if (INDEX(sb) == -1) {
    return "putstatic " + typeinfo(type) + " " +
           (SymbolTable::root->scopeName + "." + NAME(sb)) + "\n";
  } else if (INDEX(sb) != -2) {
    return "istore " + INDEX_S(sb) + "\n";
  }
  return "";
}

std::string CodeGenerate::getLabel() {
  std::stringstream ss;
  ss << "L" << this->labelCount;
  this->labelCount++;
  return ss.str();
}