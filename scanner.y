%{
  #include "type.hh"
  #include "symbolTable.hh"
  #include "colorized.hh"
  #define IS_SAME(a, b) (strcmp((a), (b)) == 0)
  #define SHOW(msg) { if(showContext) std::cout << (msg) << "\n"; }
  #define YYDEBUG 1

  #define P_CTX(t) (t).first
  #define P_TYPE(t) (t).second

  #define RELATION_OPERATION(lt ,rt)                                         \
  auto calcType = (P_TYPE(lt) & P_TYPE(rt));                                 \
  if ((calcType != T_INT) && (calcType != T_FLOAT)) {                        \
    std::cout << red("Fatal Error:")                                         \
              << "Only allow same-type, but receive "                        \
              << keyword(typeinfo(P_TYPE(lt))) << " , "                      \
              << keyword(typeinfo(P_TYPE(rt))) << "\n";                      \
    std::exit(-1);                                                           \
  }                                                                          \
  


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
  std::vector<uint8_t> arglist;
  auto formatArgs = [](std::vector<uint8_t> v) {
    std::string list = "";
    std::string spe = "";
    for(auto& t: v) {
      list += spe + typeinfo(t);
      spe = ",";
    }
    return list;
  };
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
%left '+' '-'
%left '*' '/'

%type<context> literalValue
%type<context> fn invoke stmt
%type<context> rval lval val expression
%type<type> types

%%

program:
  CLASS IDENTIFIER { st.create(P_CTX($2)); } '{' stmts '}' {
  }
;

stmts:
  stmt
| stmt stmts
| %empty
;

optionScope:
  stmt
| '{' stmts '}'

loop:
  WHILE  '(' expression ')' optionScope {
    std::cout << "while-loop" << "\n";
  }
| FOR  '(' IDENTIFIER IN expression RANGE expression ')' optionScope {
    std::cout << "for-loop" << "\n";
}
;

condition:
  IF  '(' expression ')' optionScope { 
    std::cout << "if-condition" << "\n";
  }
| IF  '(' expression ')' optionScope ELSE  optionScope {
    std::cout << "if-else-condition" << "\n";
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
      std::cout << red("Fatal Error:") <<  "Not allow assign "
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
| '(' expression ')' {
    $$ = $2;
  }
| val LT expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val LTE expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val GT expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val GTE expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val EQ expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val NE expression {
    RELATION_OPERATION($1, $3)
    $$ = std::make_pair("" , T_BOOL);
  }
| val '+' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '-' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '*' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '/' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '%' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '|' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val '&' expression {
    $$ = std::make_pair("" , T_INT);
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
    $$ = std::make_pair("fn_invoke" , TYPE(symbol) & T_CONST);
  }
;

params:
  expression
| expression ',' params
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

