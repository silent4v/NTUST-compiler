%{
  #include "type.hh"
  #include "symbolTable.hh"
  #include "colorized.hh"
  #define IS_SAME(a, b) (strcmp((a), (b)) == 0)
  #define YYDEBUG 1
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
%type<context> fn
%type<context> rval lval val expression
%type<type> types

%%

program:
  CLASS IDENTIFIER { st.create($2.first); } '{' utils '}' {
  }
;

utils:
  stmts
| loop
| condition
;

stmts:
  stmts stmt
| stmt
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
  lval '=' expression
| PRINT expression
| PRINTLN expression
| READ lval
| RETURN expression
| RETURN
| defines
| loop
| condition
;

expression:
 '(' expression ')' {
   $$ = $2;
 }
| expression LT expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression LTE expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression GT expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression GTE expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression EQ expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression NE expression {
    $$ = std::make_pair("" , T_BOOL);
  }
| expression '+' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '-' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '*' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '/' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '%' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '|' expression {
    $$ = std::make_pair("" , T_INT);
  }
| expression '&' expression {
    $$ = std::make_pair("" , T_INT);
  }
| val
;

val:
  rval
| lval
;

lval:
  IDENTIFIER {
    auto var = st.lookup($1.first);
    $$ = std::make_pair(VALUE(var), TYPE(var));
  }
| IDENTIFIER '[' expression ']' {
    auto var = st.lookup($1.first);
    $$ = std::make_pair(VALUE(var), TYPE(var));
  }
;

rval:
  IDENTIFIER '(' params ')' {
    $$ = std::make_pair("fn_invoke" , T_VOID);
  }
| literalValue
;

params:
  params ',' expression
| expression
| %empty
;

defines:
  defines define
| define
;

define:
  variables
| functions
;

functions:
  functions function
| function
;

function:
  fn '(' args ')' '{' stmts '}' {
    std::cout << keyword("Function") << "<void()> " << $1.first << "\n";
    st.exit();
    arglist.clear();
    st.insert($1.first , T_FN | T_VOID );
  }
| fn '(' args ')' ':' types '{' stmts '}' {
    std::cout << keyword("Function")
              << "<" << typeinfo($6) << "(" << formatArgs(arglist) << ")> " 
              << $1.first << "\n";
    st.exit();
    arglist.clear();
    st.insert($1.first , T_FN | $6 );
  }
;

fn:
  FUN IDENTIFIER {
    st.enter($2.first);
    $$ = make_pair($2.first, T_FN);
  }
;

args:
  args ',' arg
| arg
| %empty
;

arg:
  IDENTIFIER ':' types {
    st.insert($1.first , T_ARG | $3 );
    arglist.push_back( $3 );
  }
;

variables:
  variables variable
| variable
;

variable:
  decl
| cdecl
;

decl:
  VAR IDENTIFIER ':' types {
    st.insert($2.first, $4);
  }
| VAR IDENTIFIER ':' types '=' expression {
    typeCheck($4, $6.second);
    st.insert($2.first, $4);
  }
| VAR IDENTIFIER '=' expression {
    st.insert($2.first, $4.second);
  }
| VAR IDENTIFIER ':' types '[' expression ']' {
    st.insert($2.first, $4 | T_ARRAY);
  }
;

cdecl:
  VAL IDENTIFIER ':' types '=' expression {
    typeCheck($4, $6.second);
    st.insert($2.first, $4 | T_CONST);
  }
| VAL IDENTIFIER '=' expression {
    st.insert($2.first, $4.second | T_CONST);
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
    if( IS_SAME(argv[i], "-df") ) tokenFlow = true;
    if( IS_SAME(argv[i], "-ds") ) yydebug = 3;
    if( IS_SAME(argv[i], "-dt") ) lexHint = true;
    if( IS_SAME(argv[i], "-dst") ) st.enableDebug();
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
  printf("Filename: %s\n", filename.c_str());
  printf("State Debug: %s\n", yydebug == 3 ? "true" : "false");
  printf("Token Info: %s\n", lexHint ? "print" : "slient");
  puts("");

  puts("- - - - - Begin parsing - - - - -");
  yyparse();
  puts("\n- - - - - End   parsing - - - - -");
  st.print();
  return 0;
}

