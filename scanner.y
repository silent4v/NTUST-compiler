%{
  #include "type.hh"
  #include "symbolTable.hh"
  #include "colorized.hh"
  #include "codeGenerate.hh"
  #include <string>

  #define IS_SAME(a, b) (strcmp((a), (b)) == 0)
  #define SHOW(msg) { if(showContext) std::cout << (msg) << "\n"; }
  #define YYDEBUG 1

  #define P_CTX(t) (t).first
  #define P_TYPE(t) (t).second

  #define SUFFIX(a, b, op) ((a).first + " " + (b).first + " " + op)

  #define RELATION_OPERATION(lt ,rt, _op_)                                      \
  auto ll = P_TYPE(lt) & (T_INT | T_FLOAT);                                     \
  auto rr = P_TYPE(rt) & (T_INT | T_FLOAT);                                     \
  if(((ll != T_INT) && (ll != T_FLOAT)) || ((rr != T_INT) && (rr != T_FLOAT))){ \
    std::cout << red("Fatal Error: ")                                           \
              << "operation" << _op_                                            \
              << " Only allow same-number-type, but receive ["                  \
              << P_CTX(lt) << ":" <<keyword(typeinfo(P_TYPE(lt))) << "] , ["    \
              << P_CTX(rt) << ":" <<keyword(typeinfo(P_TYPE(rt))) << "]\n";     \
    std::exit(-1);                                                              \
  }                                                                             \

  #define LOGIC_OPERATION(lt ,rt, _op_)                                         \
  auto ll = P_TYPE(lt);                                                         \
  auto rr = P_TYPE(rt);                                                         \
  if((ll != T_BOOL) || (rr != T_BOOL)){ \
    std::cout << red("Fatal Error: ")                                           \
              << "operation" << _op_                                            \
              << " Only allow same-number-type, but receive ["                  \
              << P_CTX(lt) << ":" <<keyword(typeinfo(P_TYPE(lt))) << "] , ["    \
              << P_CTX(rt) << ":" <<keyword(typeinfo(P_TYPE(rt))) << "]\n";     \
    std::exit(-1);                                                              \
  }                                                                             \

  #define CALC_OPERATION(lt ,rt)                                                \
  auto ll = P_TYPE(lt) & (T_INT | T_FLOAT);                                     \
  auto rr = P_TYPE(rt) & (T_INT | T_FLOAT);                                     \
  if(((ll != T_INT) && (ll != T_FLOAT)) || ((rr != T_INT) && (rr != T_FLOAT))){ \
    std::cout << red("Fatal Error: ")                                           \
              << "Calc allow number-type, but receive ["                        \
              << P_CTX(lt) << ":" <<keyword(typeinfo(P_TYPE(lt))) << "] , ["    \
              << P_CTX(rt) << ":" <<keyword(typeinfo(P_TYPE(rt))) << "]\n";     \
    std::exit(-1);                                                              \
  }                                                                             \

  extern "C" 
  {
    void yyerror(const char* s);
  }
  extern int linenum;
  extern int yydebug;
  extern bool lexHint;
  extern bool tokenFlow;
  extern SymbolTable st;
  extern char* yytext;
  extern int yylex(void);

  /* Decl */
  bool showContext = false;
  std::vector<uint8_t> arglist = {};
  std::vector<uint8_t> paramlist = {};
  CodeGenerate gen;
  std::string globalDecl = "";
  std::string stmtsAsm = "";
  std::string stmtsAsmTemp = "";
  std::string classTemplate = "";
  /* if-else label */
  std::string elseLabel = "";
  std::string exitLabel = "";

  /* loop label */
  std::string beginLabel;
  std::string endLabel;
  std::string forStart = "";
  std::string forEnd = "";
  std::deque<std::string> tempStack {};

  /* Utils */
  auto formatArgs = [](std::vector<uint8_t> v) {
    std::string list = "";
    std::string spe = "";
    for(auto& t: v) {
      list += spe + typeinfo(t);
      spe = ",";
    }
    return list;
  };

  void compareVec(std::vector<uint8_t>& a, std::vector<uint8_t>& b) {
    if(a.size() != b.size()) {
      std::cout << red("Fatal error: ") << "Args define & paramlist not match\n";
      std::exit(-1);
    }
    for(int i = 0; i < a.size(); ++i) {
      auto typeA = (a.at(i) == T_INT || a.at(i) == T_FLOAT) ? 6 : a.at(i);
      auto typeB = (b.at(i) == T_INT || b.at(i) == T_FLOAT) ? 6 : b.at(i);
      typeA = typeA & TYPE_MASK;
      typeB = typeB & TYPE_MASK;
      if((typeA & typeB) == 0) {
        std::cout << red("Fatal error: ") << "At args[" << i+1 << "] ,"
                  << symbol(typeinfo(typeA)) << " not compatible with " << symbol(typeinfo(typeB))
                  << "\n";
        std::exit(-1);
      }
    }
  }

  auto genBranch(std::string l1, std::string l2, std::string cmd) {
    std::stringstream ss;
    ss << "    isub\n" <<
          "    " << cmd << " " << l1 << "\n" <<
          "    iconst_0\n" <<
          "    goto " << l2 << "\n" <<
          l1 << ": iconst_1\n" <<
          l2 << ": @loop\n";
          
    SHOW("Branch ---> " + ss.str());
    return ss.str();
  }
%}

%token<state> IF ELSE CASE
%token<state> WHILE FOR IN CONTINUE BREAK RANGE
%token<state> LT LTE GT GTE EQ NE
%token<state> VAL VAR FUN CLASS
%token<state> PRINT PRINTLN READ RETURN
%token<type> INT FLOAT BOOL STRING
%token<context> INT_VALUE FLOAT_VALUE BOOL_VALUE STRING_VALUE
%token<context> PARAMETER IDENTIFIER

%right '='
%left '&' '|'
%left '%'
%left '+' '-'
%left '*' '/'

%type<context> literalValue
%type<context> fn invoke stmt
%type<context> rval lval val expression
%type<type> types

%nonassoc UNARY

%%

program:
  CLASS IDENTIFIER { 
    st.create(P_CTX($2));
    classTemplate = gen.initial(P_CTX($2));
  } '{' stmts '}' {
    std::cout << "END";
  }
;

stmts:
  stmt
| stmt stmts
| %empty
;

optionScope:
  stmt {
    std::cout << "[nopt-scope-stmt]\n";
    tempStack.push_back(stmtsAsm);
    stmtsAsm.clear();
  }
| '{' { st.enter("internal:scope"); } stmts '}' { 
    std::cout << "[opt-scope-stmt]\n";
    tempStack.push_back(stmtsAsm);
    stmtsAsm.clear();
    st.exit();
  }
;

loop:
  WHILE {
    st.enter("internal:while");
    beginLabel = gen.getLabel() + "begin";
    endLabel = gen.getLabel() + "end";
    stmtsAsmTemp = stmtsAsm;
    stmtsAsm = "";
  } '(' expression ')' optionScope {
    typeCheck(P_TYPE($4) & TYPE_MASK, T_BOOL);
    std::cout << purple("[scope]") << "while-loop" << "\n";
    /* generate-loop */
    auto optScopeStmt = tempStack.front();

    if(optScopeStmt.find("@loop") != std::string::npos) {
      optScopeStmt.replace(optScopeStmt.find("@loop"),
                            5, "ifeq " + endLabel + "\n");
    }
    stmtsAsm += stmtsAsmTemp;
    stmtsAsm += beginLabel + ":\n";
    stmtsAsm += optScopeStmt;
    stmtsAsm += "goto "+ beginLabel + "\n";
    stmtsAsm += endLabel + ":\n";
    tempStack.pop_front();
    beginLabel = "";
    endLabel = "";
  }
| FOR { st.enter("internal:for"); } '(' IDENTIFIER IN expression RANGE expression ')' {
    stmtsAsm.pop_back();
    auto br = stmtsAsm.find_last_of("\n");
    stmtsAsm = stmtsAsm.substr(0, br);
    br = stmtsAsm.find_last_of("\n");
    stmtsAsmTemp = stmtsAsm.substr(0, br+1);
    forStart = P_CTX($6);
    forEnd = P_CTX($8);
    stmtsAsm = "";
  } optionScope {
    typeCheck(P_TYPE($6) & TYPE_MASK, T_INT);
    typeCheck(P_TYPE($8) & TYPE_MASK, T_INT);
    std::cout << purple("[scope]") << "for-loop" << "\n";

    auto sb = st.lookup(P_CTX($4));
    auto optScopeStmt = tempStack.front();
    

    beginLabel = gen.getLabel() + "begin";
    endLabel = gen.getLabel() + "end";

    /* restore */
    stmtsAsm += stmtsAsmTemp;
    /* initial */
    stmtsAsm += "sipush " + forStart + "\n";
    stmtsAsm += gen.setVar(sb);
    /* check-condition */
    stmtsAsm += beginLabel + ":\n";
    stmtsAsm += gen.getVar(sb);
    stmtsAsm += "sipush " + forEnd + "\n";
    stmtsAsm += genBranch(gen.getLabel(), gen.getLabel(), "ifle");
    /* loop-body */
    stmtsAsm += "ifeq " + endLabel + "\n";
    stmtsAsm += optScopeStmt;
    /* incr */
    stmtsAsm += gen.getVar(sb);
    stmtsAsm += "sipush 1\n";
    stmtsAsm += "iadd\n";
    stmtsAsm += gen.setVar(sb);
    stmtsAsm += "goto "+ beginLabel + "\n";
    stmtsAsm += endLabel + ":\n";

    /* delete */
    if(stmtsAsm.find("@loop") != std::string::npos) {
      stmtsAsm.replace(stmtsAsm.find("@loop"),
                            5, "");
    }
    tempStack.pop_front();
    beginLabel = "";
    endLabel = "";
    stmtsAsmTemp = "";
  }
;

if: IF '(' expression ')' {
    typeCheck(P_TYPE($3) & TYPE_MASK, T_BOOL);
    std::cout << purple("[scope]") << "if-condition" << "\n";
    elseLabel = gen.getLabel() + "else";
    exitLabel = gen.getLabel() + "exit";
    stmtsAsmTemp = stmtsAsm;
    stmtsAsm = "";
  }

condition:
  if optionScope {
    auto ifStmts = tempStack.front();
    tempStack.pop_front();

    stmtsAsm += stmtsAsmTemp;
    stmtsAsm += "ifeq " + elseLabel + "\n";
    stmtsAsm += ifStmts;
    stmtsAsm += "goto " + exitLabel + "\n";
    stmtsAsm += elseLabel + ":" + "\n";
    stmtsAsm += exitLabel + ":\n";
    stmtsAsmTemp = "";
  }
| if optionScope ELSE optionScope {
    auto ifStmts = tempStack.front();
    tempStack.pop_front();
    auto elseStmts = tempStack.front();
    tempStack.pop_front();

    stmtsAsm += stmtsAsmTemp;
    stmtsAsm += "ifeq " + elseLabel + "\n";
    stmtsAsm += ifStmts;
    stmtsAsm += "goto " + exitLabel + "\n";
    stmtsAsm += elseLabel + ":" + "\n";
    stmtsAsm += elseStmts;
    stmtsAsm += exitLabel + ":\n";
    stmtsAsmTemp = "";
  }
;

stmt:
  expression
| PRINT {
    stmtsAsm += "getstatic java.io.PrintStream java.lang.System.out\n";
  } expression {
    auto type = typeinfo(P_TYPE($3)) == "string" ? "java.lang.String" : typeinfo(P_TYPE($3));
    stmtsAsm += "invokevirtual void java.io.PrintStream.print("+ type +")\n";
    $$ = std::make_pair("statement", T_VOID);
  }
| PRINTLN {
    stmtsAsm += "getstatic java.io.PrintStream java.lang.System.out\n";
  } expression {
    auto type = typeinfo(P_TYPE($3)) == "string" ? "java.lang.String" : typeinfo(P_TYPE($3));
    stmtsAsm += "invokevirtual void java.io.PrintStream.println("+ type +")\n";
    $$ = std::make_pair("statement", T_VOID);
  }
| READ lval {
    /* 用不到 */
    $$ = std::make_pair("statement", T_VOID);
  }
| RETURN expression {
    std::cout << stmtsAsm;
    $$ = std::make_pair("statement", T_VOID);
  }
| RETURN {
    $$ = std::make_pair("statement", T_VOID);
  }
| defines {
    $$ = std::make_pair("statement", T_VOID);
  }
| loop {
    $$ = std::make_pair("statement", T_VOID);
  }
| condition {
    $$ = std::make_pair("statement", T_VOID);
  }
| lval {
    stmtsAsm.pop_back();
    auto br = stmtsAsm.find_last_of("\n");
    stmtsAsm = stmtsAsm.substr(0, br);
    stmtsAsm += "\n";
    if( br == std::string::npos ) {
      stmtsAsm = "";
    }
  } '=' expression {
    if((P_TYPE($1) & P_TYPE($4)) != P_TYPE($1)) {
      std::cout << red("Fatal Error: ") <<  "Not allow assign "
                << keyword(typeinfo(P_TYPE($4)))
                << " to "
                << keyword(typeinfo(P_TYPE($1))) << "\n";
      std::exit(-1);
    }
    $$ = std::make_pair(P_CTX($1)+ " = " + P_CTX($4) , P_TYPE($1));
    auto var = st.lookup(P_CTX($1));
    std::string temp = "";
    SHOW("lval --> " + NAME(var) + "@" + INDEX_S(var));
    stmtsAsm += gen.setVar(var);
    std::cout << temp;
  }
;

expression:
  invoke
| val
| '-' expression {
    auto opaType = P_TYPE($2) & TYPE_MASK;
    if(opaType != T_INT && opaType != T_FLOAT) {
      std::cout << red("Fatal Error: ")
                << "Only allow number-type, but receive ["
                << typeinfo(P_TYPE($2))
                << "]\n";
    }
    $$ = std::make_pair("-" + P_CTX($2) , T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "ineg\n";
  } %prec UNARY
| '!' expression {
    typeCheck(P_TYPE($2) & TYPE_MASK, T_BOOL);
    $$ = std::make_pair("!" + P_CTX($2) , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "ixor\n";
  } %prec UNARY
| '(' expression ')' {
    $$ = $2;
  }
| expression LT expression {
    RELATION_OPERATION($1, $3, "<")
    $$ = std::make_pair( SUFFIX($1, $3, "<") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "iflt");
  }
| expression LTE expression {
    RELATION_OPERATION($1, $3, "<=")
    $$ = std::make_pair( SUFFIX($1, $3, "<=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "ifle");
  }
| expression GT expression {
    RELATION_OPERATION($1, $3, ">")
    $$ = std::make_pair( SUFFIX($1, $3, ">") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "ifgt");
  }
| expression GTE expression {
    RELATION_OPERATION($1, $3, ">=")
    $$ = std::make_pair( SUFFIX($1, $3, ">=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "ifge");
  }
| expression EQ expression {
    RELATION_OPERATION($1, $3, "==")
    $$ = std::make_pair( SUFFIX($1, $3, "==") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "ifeq");
  }
| expression NE expression {
    RELATION_OPERATION($1, $3, "!=")
    $$ = std::make_pair( SUFFIX($1, $3, "!=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    auto l1 = gen.getLabel(), l2 = gen.getLabel();
    stmtsAsm += genBranch(l1, l2, "ifne");
  }
| expression '*' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "*"), T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "imul\n";
  }
| expression '/' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "/"), T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "idiv\n";
  }
| expression '+' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "+"), T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "iadd\n";
  }
| expression '-' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "-"), T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "isub\n";
  }
| expression '%' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "%"), T_INT);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "irem\n";
  }
| expression '|' expression {
    LOGIC_OPERATION($1, $3, "|")
    $$ = std::make_pair( SUFFIX($1, $3, "|"), T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "ior\n";
  }
| expression '&' expression {
    LOGIC_OPERATION($1, $3, "&")
    $$ = std::make_pair( SUFFIX($1, $3, "&"), T_BOOL);
    SHOW( "--> " + P_CTX($$) )
    stmtsAsm += "iand\n";
  }
;

val:
  rval
| lval
;

lval:
  IDENTIFIER {
    auto var = st.lookup(P_CTX($1));
    $$ = std::make_pair(NAME(var), TYPE(var));
    stmtsAsm += gen.getVar(st.lookup(NAME(var), false));
  }
| IDENTIFIER '[' expression ']' {
    auto var = st.lookup(P_CTX($1));
    $$ = std::make_pair(NAME(var), TYPE(var));
  }
;

rval:
  literalValue {
    stmtsAsm += (P_TYPE($1) == T_STRING ? "" : "sipush ") + P_CTX($1) + "\n";
    $$ = $1;
  }
;

invoke:
  IDENTIFIER '(' params ')' {
    auto symbol = st.lookup(P_CTX($1));
    SHOW("invoke: " + NAME(symbol))
    auto fArgs = st.formalArgs(NAME(symbol));
    std::reverse(paramlist.begin(), paramlist.end());
    SHOW("---->    arg: " + formatArgs(fArgs))
    SHOW("----> params: " + formatArgs(paramlist))
    compareVec(fArgs, paramlist);
    $$ = std::make_pair("fn_invoke" , TYPE(symbol) & TYPE_MASK);
    paramlist.clear();
    stmtsAsm += ("invokestatic " + typeinfo(TYPE(symbol) & TYPE_MASK) + " " + (SymbolTable::root->scopeName) + "." + NAME(symbol) 
                  + "(" + formatArgs(fArgs) + ") ") +"\n";
  }
;

params:
  expression {
    paramlist.push_back(P_TYPE($1));
  }
| expression ',' params {
    paramlist.push_back(P_TYPE($1));
  }
| %empty
;

defines:
  define
| define defines
;

define:
  variables
| functions
;

functions:
  function
| function functions
;

function:
  fn '(' args ')' '{' stmts '}' {
    std::cout << keyword("Function") << "<void()> " << P_CTX($1) << "\n";
    st.exit();
    arglist.clear();
    st.insert(P_CTX($1) , T_FN | T_VOID );
    auto funcAsm = gen.funcDecl(P_CTX($1), "void", formatArgs(arglist), stmtsAsm);
    if(P_CTX($1) == "main") {
      funcAsm = gen.funcDecl("main", "void", "java.lang.String[]", stmtsAsm);
    }
    gen.put(funcAsm);
    stmtsAsm = "";
  }
| fn '(' args ')' ':' types '{' stmts '}' {
    std::cout << keyword("Function")
              << "<" << typeinfo($6) << "(" << formatArgs(arglist) << ")> " 
              << P_CTX($1) << "\n";
    st.exit();
    st.insert(P_CTX($1) , T_FN | $6 );
    auto funcAsm = gen.funcDecl(P_CTX($1), typeinfo($6), formatArgs(arglist), stmtsAsm);
    gen.put(funcAsm);
    stmtsAsm = "";
    arglist.clear();
  }
;

fn:
  FUN IDENTIFIER {
    st.enter(P_CTX($2));
    $$ = make_pair(P_CTX($2), T_FN);
    gen.localCount = 0;
    stmtsAsm = "";
  }
;

args:
  arg
| arg ',' args
| %empty
;

arg:
  IDENTIFIER ':' types {
    st.insert(P_CTX($1) , T_ARG | $3 , gen.localCount);
    arglist.push_back( $3 );
    ++gen.localCount;
  }
;

variables:
  variable
| variable variables
;

variable:
  decl
| cdecl
;

decl:
  VAR IDENTIFIER ':' types {
    if( st.isGlobal() ) {
      st.insert(P_CTX($2), $4);
      globalDecl += "  field static " + typeinfo($4) + " " + P_CTX($2) + "\n";
    } else {
      st.insert(P_CTX($2), $4, gen.localCount);
      stmtsAsm += "istore ";
      stmtsAsm += (char)(gen.localCount+48);
      stmtsAsm += "\n";
      ++gen.localCount;
    }
  }
| VAR IDENTIFIER ':' types '=' expression {
    typeCheck($4, P_TYPE($6));
    if( st.isGlobal() ) {
      st.insert(P_CTX($2), $4);
      globalDecl += "  field static " + typeinfo($4) + " " + P_CTX($2) + " = " + P_CTX($6) + "\n";
    } else {
      st.insert(P_CTX($2), $4, gen.localCount);
      std::string temp;
      temp += (
        "sipush " + P_CTX($6) + "\n" +
        "istore " + AS_STR(gen.localCount) + "\n"
      );
      SHOW(red("INITIAL") + "\n" + temp);
      stmtsAsm += "istore ";
      stmtsAsm += (char)(gen.localCount+48);
      stmtsAsm += "\n";
      ++gen.localCount;
    }
  }
| VAR IDENTIFIER '=' expression {
    if( st.isGlobal() ) {
      st.insert(P_CTX($2), P_TYPE($4));
      globalDecl += "  field static " + typeinfo(P_TYPE($4)) + " " + P_CTX($2) + " = " + P_CTX($4) + "\n";
    } else {
      st.insert(P_CTX($2), P_TYPE($4), gen.localCount);
      std::string temp;
      temp += (
        "sipush " + P_CTX($4) + "\n" +
        "istore " + AS_STR(gen.localCount) + "\n"
      );
      SHOW(red("INITIAL") + "\n" + temp);
      stmtsAsm += "istore ";
      stmtsAsm += (char)(gen.localCount+48);
      stmtsAsm += "\n";
      ++gen.localCount;
    }
  }
| VAR IDENTIFIER ':' types '[' expression ']' {
    typeCheck(T_INT, P_TYPE($6) & TYPE_MASK);
    st.insert(P_CTX($2), $4 | T_ARRAY);
  }
| VAR IDENTIFIER {
  /**
   * 助教與黃老師認為該語法是合理的
   * Mircosoft/VC++ GNU/g++ Apple/clang++ 皆不允許C++出現 auto i 這種語法
   * Google 的 golang 也不允許出現 var i
   * Mozilla 的 Rust 亦不允許出現 let i
   * 甚至 Kotlin 也無法讓 var i 通過編譯
   * 該語法為型別推導，意思是給個型別讓編譯器推導，但是黃老師的助教認為不用給型別也可以推導
   * 即使違反 Mircosoft、GNU、Apple、Google、Mozilla 若干組織的編譯器實作
   * 還是逼學生實作，否則不予計分。
   * 屈於助教與教授淫威，只好勉強實現該不正確的語法
   */
  st.insert(P_CTX($2), T_VOID);
}
;

cdecl:
  VAL IDENTIFIER ':' types '=' expression {
    typeCheck($4, P_TYPE($6));
    if( st.isGlobal() ) {
      st.insert(P_CTX($2), $4 | T_CONST);
      globalDecl += "  field static " + typeinfo($4) + " " + P_CTX($2) + " = " + P_CTX($6) + "\n";
    } else {
      st.insert(P_CTX($2), $4 | T_CONST, gen.localCount);
      std::string temp;
      temp += (
        "sipush " + P_CTX($6) + "\n" +
        "istore " + AS_STR(gen.localCount) + "\n"
      );
      SHOW(red("INITIAL") + "\n" + temp);
      stmtsAsm += "istore ";
      stmtsAsm += (char)(gen.localCount+48);
      stmtsAsm += "\n";
      ++gen.localCount;
    }
  }
| VAL IDENTIFIER '=' expression {
    if( st.isGlobal() ) {
      st.insert(P_CTX($2), P_TYPE($4) | T_CONST);
      globalDecl += "  field static " + typeinfo(P_TYPE($4)) + " " + P_CTX($2) + " = " + P_CTX($4) + "\n";
    } else {
      st.insert(P_CTX($2), P_TYPE($4) | T_CONST, gen.localCount);
      std::string temp;
      temp += (
        "sipush " + P_CTX($4) + "\n" +
        "istore " + AS_STR(gen.localCount) + "\n"
      );
      SHOW(red("INITIAL") + "\n" + temp);
      stmtsAsm += "istore ";
      stmtsAsm += (char)(gen.localCount+48);
      stmtsAsm += "\n";
      ++gen.localCount;
    }
  }
;

types:
  BOOL    { $$ = T_BOOL;   }
| INT     { $$ = T_INT;    }
| FLOAT   { $$ = T_FLOAT;  }
| STRING  { $$ = T_STRING; }
;

literalValue:
  BOOL_VALUE
| INT_VALUE
| FLOAT_VALUE
| STRING_VALUE {
  $$ = std::make_pair("ldc \"" + P_CTX($1) + "\"", T_STRING);
}
;
%%

void yyerror(const char* s)
{
  std::cerr << "-->  Stop: `" << yytext << "` @line" << linenum << "\n";
  std::cerr << "-->  Get Error: " << s << "\n";
  exit(-1);
}

int main(int argc, char** argv)
{
  /* initial config */
  FILE* fs = stdin;
  std::string filename = "#stdin";

  /* select config */
  for(int i = 0 ; i < argc ; ++i)
  {
    if( IS_SAME(argv[i], "-dctx") ) showContext = true;
    if( IS_SAME(argv[i], "-dtext") ) tokenFlow = true;
    if( IS_SAME(argv[i], "-dlex") ) lexHint = true;
    if( IS_SAME(argv[i], "-dsymbols") ) st.enableDebug();
    if( IS_SAME(argv[i], "-dyy") ) yydebug = 3;
    if( IS_SAME(argv[i], "-f") ) {
      filename = argv[i+1];
      fs = fopen(filename.c_str(), "r");
    }
  }

  if( fs == NULL )
  {
    std::cout << "Open file failed: " << argv[1] << "\n";
    return -1;
  }

  extern FILE* yyin;
  yyin = fs;
  puts("- - - - - Config - - - - -");
  std::cout << "(-f)        Filename: " << purple(filename) << "\n";
  std::cout << "(-dctx)     Context Info: "      << (showContext ? green("print") : red("slient"))   << "\n";
  std::cout << "(-dtext)    Parsing progress: "  << (tokenFlow ? green("print") : red("slient"))     << "\n";
  std::cout << "(-dlex)     Lexical Info: "      << (lexHint ? green("print") : red("slient"))       << "\n";
  std::cout << "(-dsymbols) Symbol Table Info: " << (st.debug_mode ? green("print") : red("slient")) << "\n";
  std::cout << "(-dyy)      YYState Info: "      << (yydebug ? green("print") : red("slient"))       << "\n";
  puts("");
  puts("- - - - - Begin parsing - - - - -");
  yyparse();
  puts("\n- - - - - End   parsing - - - - -");
  st.print();

  classTemplate.replace(classTemplate.find("@global_decl"), 12, globalDecl);
  classTemplate.replace(classTemplate.find("@class_body"), 11, gen.codeBuffer);
  
  auto iter = classTemplate.find("@loop");
  while(iter != std::string::npos) {
    classTemplate.replace(iter, 5 , "");
    iter = classTemplate.find("@loop");
  }
  gen.flush(classTemplate);
  return 0;
}
