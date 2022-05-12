%{
  #include "type.hh"
  #include "symbolTable.hh"
  #include "colorized.hh"

  extern "C" 
  {
    void yyerror(const char* s);
  }
  extern int yylex(void);
  extern std::string buf;
  extern std::string declType;
%}


%token<type> NUMBER

%%

interge:
  NUMBER { std::cout << $1 << "\n"; }

%%

void yyerror(const char* s)
{
  std::cerr << s << "\n";
}

int main(int argc, char** argv)
{
  FILE* fs = fopen(argv[1], "r");
  if( fs == NULL )
  {
    std::cout << "Open file failed: " << argv[1] << "\n";
    return -1;
  }

  extern FILE* yyin;
  yyin = fs;
  puts("- - - - - Begin parsing");
  yyparse();
  puts("- - - - - End parsing");
  return 0;
}

