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
  extern int yydebug;
  extern bool lexHint;
  extern bool tokenFlow;
  extern char* yytext;
  extern int yylex(void);
%}

%token<state> LT LTE GT GTE EQ NE
%token<state> VAL VAR FUN CLASS
%token<type> INT FLOAT BOOL STRING
%token<type> INT_VALUE FLOAT_VALUE BOOL_VALUE STRING_VALUE
%token<context> PARAMETER IDENTIFIER

%type<type> literalValue
%type<type> types

%%

program:
  CLASS IDENTIFIER '{' defines '}'
;

defines:
  defines define
| define
| %empty
;

define:
  declares
| decl_functions
;

decl_functions:
  decl_functions decl_function
| decl_function
;

decl_function:
  FUN IDENTIFIER '(' args ')' '{'  '}' {
    std::cout << "[function<void>]" << $2;
  }
| FUN IDENTIFIER '(' args ')' ':' types '{'  '}' {
    std::cout << "[function<" << typeinfo($7) << ">]" << $2;
  }
;

args:
  args ',' arg
| arg
| %empty
;

arg:
  IDENTIFIER ':' types {
    std::cout << "[arg]" << $1 << "<" << typeinfo($3) << ">\n";
  }
;

declares:
  declares decl_variables
| decl_variables
;

decl_variables:
  decl
| cdecl
;

decl:
  VAR IDENTIFIER ':' types {
    std::cout << $2 << "<" << typeinfo($4) << ">\n";
  }
| VAR IDENTIFIER ':' types '=' literalValue {
    std::cout << $2 << "<" << typeinfo($4) << ">\n";
  }
| VAR IDENTIFIER '=' literalValue {
    std::cout << $2 << "<" << typeinfo($4) << ">\n";
  }
;

cdecl:
  VAL IDENTIFIER ':' types '=' literalValue {
    std::cout << $2 << "<" << typeinfo($4) << ">\n";
  }
| VAL IDENTIFIER '=' literalValue {
    std::cout << $2 << "<" << typeinfo($4) << ">\n";
  }
;

program:
  CLASS '{' '}'
;

types:
  BOOL    { $$ = T_BOOL;   }
| INT     { $$ = T_INT;    }
| FLOAT   { $$ = T_FLOAT;  }
| STRING  { $$ = T_STRING; }
;

literalValue:
  BOOL_VALUE    { $$ = $1; std::cout << "$1 = " << typeinfo($1) << "\n"; }
| INT_VALUE     { $$ = $1; std::cout << "$1 = " << typeinfo($1) << "\n"; }
| FLOAT_VALUE   { $$ = $1; std::cout << "$1 = " << typeinfo($1) << "\n"; }
| STRING_VALUE  { $$ = $1; std::cout << "$1 = " << typeinfo($1) << "\n"; }
;
%%

void yyerror(const char* s)
{
  std::cerr << "-->  Current: `" << yytext << "` \n";
  std::cerr << "-->  Get Error: " << s << "\n";
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
  puts("\n- - - - - End parsing - - - - -");
  return 0;
}

