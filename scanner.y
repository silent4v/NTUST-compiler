%{
  #include "type.hh"
  #include "symbolTable.hh"
  #include "colorized.hh"
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
              << " Only allow same-number-type, but receive "                   \
              << P_CTX(lt) << ":" <<keyword(typeinfo(P_TYPE(lt))) << " , "      \
              << P_CTX(rt) << ":" <<keyword(typeinfo(P_TYPE(rt))) << "\n";      \
    std::exit(-1);                                                              \
  }                                                                             \
  
  #define CALC_OPERATION(lt ,rt)                                                \
  auto ll = P_TYPE(lt) & (T_INT | T_FLOAT);                                     \
  auto rr = P_TYPE(rt) & (T_INT | T_FLOAT);                                     \
  if(((ll != T_INT) && (ll != T_FLOAT)) || ((rr != T_INT) && (rr != T_FLOAT))){ \
    std::cout << red("Fatal Error: ")                                           \
              << "Calc allow number-type, but receive "                         \
              << P_CTX(lt) << ":" <<keyword(typeinfo(P_TYPE(lt))) << " , "      \
              << P_CTX(rt) << ":" <<keyword(typeinfo(P_TYPE(rt))) << "\n";      \
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
  bool showContext = false;
  std::vector<uint8_t> arglist = {};
  std::vector<uint8_t> paramlist = {};

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

%nonassoc '!'
%nonassoc UMINUS

%%

program:
  CLASS IDENTIFIER { st.create(P_CTX($2)); } '{' stmts '}' {
    std::cout << "END";
  }
;

stmts:
  stmt
| stmt stmts
| %empty
;

loop:
  WHILE { st.enter("internal:while"); } '(' expression ')' optionScope {
    typeCheck(P_TYPE($4) & TYPE_MASK, T_BOOL);
    std::cout << purple("[scope]") << "while-loop" << "\n";
  }
| FOR { st.enter("internal:for"); } '(' IDENTIFIER IN expression RANGE expression ')' optionScope {
    typeCheck(P_TYPE($6) & TYPE_MASK, T_INT);
    typeCheck(P_TYPE($8) & TYPE_MASK, T_INT);
    std::cout << purple("[scope]") << "for-loop" << "\n";
  }
;

optionScope:
  stmt
| '{' { { st.enter("internal:scope"); } } stmts '}'
;

condition:
  IF '(' expression ')' optionScope {
    typeCheck(P_TYPE($3) & TYPE_MASK, T_BOOL);
    std::cout << purple("[scope]") << "if-condition" << "\n";
  }
| IF '(' expression ')' optionScope ELSE  optionScope {
    typeCheck(P_TYPE($3) & TYPE_MASK, T_BOOL);
    std::cout << purple("[scope]") << "if-else-condition" << "\n";
  }
;

stmt:
  expression
| PRINT expression {
    $$ = std::make_pair("statement", T_VOID);
  }
| PRINTLN expression {
    $$ = std::make_pair("statement", T_VOID);
  }
| READ lval {
    $$ = std::make_pair("statement", T_VOID);
  }
| RETURN expression {
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
| lval '=' expression {
    if((P_TYPE($1) & P_TYPE($3)) != P_TYPE($1)) {
      std::cout << red("Fatal Error: ") <<  "Not allow assign "
                << keyword(typeinfo(P_TYPE($3)))
                << " to "
                << keyword(typeinfo(P_TYPE($1))) << "\n";
      std::exit(-1);
    }
    $$ = std::make_pair(P_CTX($1)+ " = " + P_CTX($3) , P_TYPE($1));
  }
;

expression:
  invoke
| val
| '-' expression {
    auto opaType = P_TYPE($2) & TYPE_MASK;
    if(opaType != T_INT && opaType != T_FLOAT) {
      std::cout << red("Fatal Error: ")
                << "Only allow number-type, but receive "
                << typeinfo(P_TYPE($2))
                << "\n";
    }
    $$ = std::make_pair("-" + P_CTX($2) , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  } %prec UMINUS
| '!' expression {
    typeCheck(P_TYPE($2) & TYPE_MASK, T_BOOL);
    $$ = std::make_pair("!" + P_CTX($2) , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| '(' expression ')' {
    $$ = $2;
  }
| expression LT expression {
    RELATION_OPERATION($1, $3, "<")
    $$ = std::make_pair( SUFFIX($1, $3, "<") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression LTE expression {
    RELATION_OPERATION($1, $3, "<=")
    $$ = std::make_pair( SUFFIX($1, $3, "<=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression GT expression {
    RELATION_OPERATION($1, $3, ">")
    $$ = std::make_pair( SUFFIX($1, $3, ">") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression GTE expression {
    RELATION_OPERATION($1, $3, ">=")
    $$ = std::make_pair( SUFFIX($1, $3, ">=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression EQ expression {
    RELATION_OPERATION($1, $3, "==")
    $$ = std::make_pair( SUFFIX($1, $3, "==") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression NE expression {
    RELATION_OPERATION($1, $3, "!=")
    $$ = std::make_pair( SUFFIX($1, $3, "!=") , T_BOOL);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '*' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "*"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '/' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "/"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '+' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "+"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '-' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "-"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '%' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "%"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '|' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "|"), T_INT);
    SHOW( "--> " + P_CTX($$) )
  }
| expression '&' expression {
    CALC_OPERATION($1, $3)
    $$ = std::make_pair( SUFFIX($1, $3, "&"), T_INT);
    SHOW( "--> " + P_CTX($$) )
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
  }
| IDENTIFIER '[' expression ']' {
    auto var = st.lookup(P_CTX($1));
    $$ = std::make_pair(NAME(var), TYPE(var));
  }
;

rval:
  literalValue {
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
  }
| fn '(' args ')' ':' types '{' stmts '}' {
    std::cout << keyword("Function")
              << "<" << typeinfo($6) << "(" << formatArgs(arglist) << ")> " 
              << P_CTX($1) << "\n";
    st.exit();
    arglist.clear();
    st.insert(P_CTX($1) , T_FN | $6 );
  }
;

fn:
  FUN IDENTIFIER {
    st.enter(P_CTX($2));
    $$ = make_pair(P_CTX($2), T_FN);
  }
;

args:
  arg
| arg ',' args
| %empty
;

arg:
  IDENTIFIER ':' types {
    st.insert(P_CTX($1) , T_ARG | $3 );
    arglist.push_back( $3 );
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
    st.insert(P_CTX($2), $4);
  }
| VAR IDENTIFIER ':' types '=' expression {
    typeCheck($4, P_TYPE($6));
    st.insert(P_CTX($2), $4);
  }
| VAR IDENTIFIER '=' expression {
    st.insert(P_CTX($2), P_TYPE($4));
  }
| VAR IDENTIFIER ':' types '[' expression ']' {
    typeCheck(T_INT, P_TYPE($6) & TYPE_MASK);
    st.insert(P_CTX($2), $4 | T_ARRAY);
  }
;

cdecl:
  VAL IDENTIFIER ':' types '=' expression {
    typeCheck($4, P_TYPE($6));
    if(lexHint) { std::cout << ""; }
    st.insert(P_CTX($2), $4 | T_CONST);
  }
| VAL IDENTIFIER '=' expression {
    st.insert(P_CTX($2), P_TYPE($4) | T_CONST);
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
| STRING_VALUE
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
  FILE* fs = NULL;
  std::string filename = "%empty";

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
  std::cout << "Filename: " << purple(filename) << "\n";
  std::cout << "Context Info: "      << (showContext ? green("print") : red("slient"))   << "\n";
  std::cout << "Parsing progress: "  << (tokenFlow ? green("print") : red("slient"))     << "\n";
  std::cout << "Lexical Info: "      << (lexHint ? green("print") : red("slient"))       << "\n";
  std::cout << "Symbol Table Info: " << (st.debug_mode ? green("print") : red("slient")) << "\n";
  std::cout << "YYState Info: "      << (yydebug ? green("print") : red("slient"))       << "\n";
  puts("");
  puts("- - - - - Begin parsing - - - - -");
  yyparse();
  puts("\n- - - - - End   parsing - - - - -");
  st.print();
  return 0;
}

