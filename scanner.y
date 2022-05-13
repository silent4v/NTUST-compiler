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
  extern char* yytext;
  extern int yylex(void);
%}

%token<state> IF ELSE CASE
%token<state> WHILE FOR IN CONTINUE BREAK RANGE
%token<state> LT LTE GT GTE EQ NE
%token<state> VAL VAR FUN CLASS
%token<state> PRINT PRINTLN READ RETURN
%token<type> INT FLOAT BOOL STRING
%token<type> INT_VALUE FLOAT_VALUE BOOL_VALUE STRING_VALUE
%token<context> PARAMETER IDENTIFIER

%right '='
%left '+' '-'
%left '*' '/'

%type<type> literalValue
%type<type> types
%type<type> rval lval val
%type<type> expression

%%

program:
  CLASS IDENTIFIER '{' utils '}'
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
    std::cout << "operator< : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression LTE expression {
    std::cout << "operator<= : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression GT expression {
    std::cout << "operator> : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression GTE expression {
    std::cout << "operator>= : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression EQ expression {
    std::cout << "operator== : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression NE expression {
    std::cout << "operator!= : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_BOOL;
  }
| expression '+' expression {
    std::cout << "operator+ : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '-' expression {
    std::cout << "operator- : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '*' expression {
    std::cout << "operator* : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '/' expression {
    std::cout << "operator/ : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '%' expression {
    std::cout << "operator% : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '|' expression {
    std::cout << "operator| : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| expression '&' expression {
    std::cout << "operator& : " << typeinfo($1) << ", " << typeinfo($3) << "\n";
    $$ = T_INT;
  }
| val
;

val:
  rval
| lval
;

lval:
  IDENTIFIER {
    $$ = $1.second;
  }
| IDENTIFIER '[' expression ']' {
    $$ = $1.second;
  }
;

rval:
  IDENTIFIER '(' params ')' {
    $$ = T_VOID;
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
  FUN IDENTIFIER '(' args ')' '{' stmts '}' {
    std::cout << "[function<void>]" << $2.first << "\n";
  }
| FUN IDENTIFIER '(' args ')' ':' types '{' stmts '}' {
    std::cout << "[function<" << typeinfo($7) << ">]" << $2.first << "\n";
  }
;

args:
  args ',' arg
| arg
| %empty
;

arg:
  IDENTIFIER ':' types {
    std::cout << "[arg]" << $1.first << "<" << typeinfo($3) << ">\n";
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
    std::cout << $2.first << "<" << typeinfo($4) << ">\n";
  }
| VAR IDENTIFIER ':' types '=' literalValue {
    std::cout << $2.first << "<" << typeinfo($4) << ">\n";
  }
| VAR IDENTIFIER '=' literalValue {
    std::cout << $2.first << "<" << typeinfo($4) << ">\n";
  }
| VAR IDENTIFIER ':' types '[' INT_VALUE ']' {
    std::cout << $2.first << "<" << typeinfo($4) << "[]>\n";
  }
;

cdecl:
  VAL IDENTIFIER ':' types '=' literalValue {
    std::cout << $2.first << "<" << typeinfo($4) << ">\n";
  }
| VAL IDENTIFIER '=' literalValue {
    std::cout << $2.first << "<" << typeinfo($4) << ">\n";
  }
;

types:
  BOOL    { $$ = T_BOOL;   }
| INT     { $$ = T_INT;    }
| FLOAT   { $$ = T_FLOAT;  }
| STRING  { $$ = T_STRING; }
;

literalValue:
  BOOL_VALUE    { $$ = $1; }
| INT_VALUE     { $$ = $1; }
| FLOAT_VALUE   { $$ = $1; }
| STRING_VALUE  { $$ = $1; }
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

  /* read config */
  for(int i = 0 ; i < argc ; ++i)
  {
    if( IS_SAME(argv[i], "-df") ) tokenFlow = true;
    if( IS_SAME(argv[i], "-ds") ) yydebug = 3;
    if( IS_SAME(argv[i], "-dt") ) lexHint = true;
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
  return 0;
}

