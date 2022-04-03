%{
#include <algorithm>
#include <iostream>
#include <iomanip>
#include <cstring>
#include "colorized.hh"
#include "symbolTable.hh"
#define SCAN buf += (YYText())
#define MAX_LINE_LENG 256

int linenum = 1;
extern char yytext[];
auto st = std::make_unique<SymbolTable>();
std::string buf = "";
std::string declType = "";

void token(std::string&& token, std::string desc)
{
  std::cout << "<";
  std::cout << std::left << std::setfill(' ') << std::setw(20) << ("'" + token + "'");
  std::cout << " : " << desc << ">\n";
}

void newLineDetect(std::string& buf)
{
  bool isEmpty = std::all_of(buf.cbegin(), buf.cend(), [](auto& ch) {
    return ch == ' ' | ch == '\r' | ch == '\n' | ch == '\t';
  });
  std::string output = isEmpty ? cyan("<EMPTY>") + "\n" : buf;
  reset();
  std::cout << "line " << std::right << std::setfill('0') << std::setw(2) << linenum << " :"
            << output  << std::endl;
  linenum++;
  buf.clear();
}

%}

%option c++
%option noyywrap
%option yylineno
%option debug

%x COMMENT_STATE
%x DECLARE_VAR_STATE
%x DECLARE_SCOPE_STATE
%x DECLARE_ARGS_STATE

multiCommentStart \/\*
multiCommentEnd \*\/
signalComment \/\/[^\n]*
comment       \/\/.*\n

comma     ,
colon     :
semi      ;
arrow     ->
lParent   \(
rParent   \)
lsBrack   \[
rsBrack   \]
lBrack    \{
rBrack    \}
delimiter {comma}|{colon}|{semi}|{arrow}|{lParent}|{rParent}|{lsBrack}|{rsBrack}|{lBrack}|{rBrack}

digit      [0-9]
integer    {digit}+
real       (\+|\-)?{integer}\.{integer}
scientific {integer}e(\+|\-)?{integer}
number     {real}|{scientific}|{integer}

alpha     [A-Za-z]
string    \"(.)*(\"\")?(.)*\"

add     \+
sub     \-
mul     \*
div     \/
remainder  %
arithmetic {add}|{sub}|{mul}|{div}|{remainder}

lt      <
lte     <=
gt      >
gte     >=
eq      ==
ne      !=
relational {lt}|{lte}|{gt}|{gte}|{eq}|{ne}

and     &
or      |
not     !
logic   {and}|{or}|{not}

assignment =

cAdd     \+=
cSub     \-=
cMul     \*=
cDiv     \/=
cOperator {cAdd}|{cSub}|{cMul}|{cDiv}

boolean   true|false
condition if|else|case
loops     loop|while|for|break|continue
declares  val|var|declare|class|fun
type      bool|char|string|int|float
etc       do|exit|print|println|return
keywords  {boolean}|{condition}|{loops}|{declares}|{type}|{etc}

identifier {alpha}({alpha}|{digit})*
rval {number}|{string}|{boolean}
newline (\r)*\n(\r)*
space   [ \t]*

%%


{number}     { SCAN; token(id(YYText()), "NUMBER");              }
{boolean}    { SCAN; token(id(YYText()), "BOOL");                }
{string}  {
  buf += YYText();
  auto literalValue = std::string(YYText()).substr(1, strlen(YYText())-2);
  while(literalValue.find("\"\"") != std::string::npos) {
    literalValue.replace(literalValue.find("\"\""), 2, "\"");
  }
  token(id(literalValue.c_str()), "STRING");
}

{arithmetic} { SCAN; token(operators(YYText()), "CALCULATE"); }
{assignment} { SCAN; token(operators(YYText()), "ASSIGN");    }
{lt}  { SCAN; token(operators(YYText()), "$LT");    }
{lte} { SCAN; token(operators(YYText()), "$LTE");   }
{gt}  { SCAN; token(operators(YYText()), "$GT");    }
{gte} { SCAN; token(operators(YYText()), "$GTE");   }
{eq}  { SCAN; token(operators(YYText()), "$EQ");    }
{ne}  { SCAN; token(operators(YYText()), "$NE");    }

{delimiter}  { SCAN; token(symbol(YYText()), "SYMBOL");   }

"val"|"var" { 
  SCAN; 
  token(keyword(YYText()), "KEYWORD");
  declType = (strcmp(YYText(), "var") == 0) ? "variable" : "const variable";
  BEGIN(DECLARE_VAR_STATE);
}

"fun"|"class" {
  SCAN; 
  token(keyword(YYText()), "KEYWORD");
  declType = (strcmp(YYText(), "class") == 0) ? "class" : "function";
  BEGIN(DECLARE_SCOPE_STATE);
}

{keywords}   { SCAN; token(keyword(YYText()), "KEYWORD"); }
{identifier} { SCAN; token(id(YYText()), "IDENTIFIER");   }

<DECLARE_VAR_STATE>{identifier} {
  SCAN;
  st->insert(YYText(), declType);
  token(id(YYText()), declType);
  BEGIN(INITIAL);
}

<DECLARE_SCOPE_STATE>{identifier} {
  SCAN;
  st->insert(YYText(), declType);
  token(id(YYText()), declType);
  if(declType == "class") {
    BEGIN(INITIAL);
  }
}

<DECLARE_SCOPE_STATE>"(" { SCAN; token(symbol(YYText()), "SYMBOL"); BEGIN(DECLARE_ARGS_STATE); }
<DECLARE_ARGS_STATE>{type}  { SCAN; token(keyword(YYText()), "KEYWORD"); }
<DECLARE_ARGS_STATE>":"|"," { SCAN; token(symbol(YYText()), "SYMBOL"); }
<DECLARE_ARGS_STATE>{identifier} {
  SCAN;
  declType = "parameter";
  st->insert(YYText(), declType);
  token(id(YYText()), "parameter");
}
<DECLARE_ARGS_STATE>")" { SCAN; token(symbol(YYText()), "SYMBOL"); BEGIN(INITIAL); }

{signalComment} {
  buf += comment(YYText());
}

{multiCommentStart} {
  buf += YELLOW;
  buf += YYText();
  BEGIN(COMMENT_STATE);
}

<COMMENT_STATE>{multiCommentEnd} {
  buf += comment(YYText());
  BEGIN(INITIAL);
}

{newline}   {
  SCAN;
  newLineDetect(buf);
  buf = "";
}

<COMMENT_STATE>{newline} {
  SCAN;
  newLineDetect(buf);
  buf = YELLOW;
}



<INITIAL,COMMENT_STATE,DECLARE_VAR_STATE,DECLARE_SCOPE_STATE,DECLARE_ARGS_STATE>{space}     { 
  SCAN;
}

.           {
  std::cout << "line " << linenum <<":" << buf.size()+1 << " " << buf;
  std::cout << "\nbad character: '" << YYText() << "'" << '\n';
  exit(-1);
}

<COMMENT_STATE>. {
  buf += YYText();
}

%%
#include <fstream>
#include <iostream>
#include <memory>

int main(int argc, char** argv)
{
  std::ifstream file;
  std::unique_ptr<yyFlexLexer> lexer;

  if( argc > 0 ) {
    file.open(argv[1]);
    std::cout << "filename: " << argv[1] << "\n\n";
    lexer = std::make_unique<yyFlexLexer>(&file, &std::cout);
  } else {
    lexer = std::make_unique<yyFlexLexer>();
  }
  while(lexer->yylex() != 0);
  std::cout << "line " << std::right << std::setfill('0') << std::setw(2) << linenum << ": "
            << buf << "\n\n";

  std::cout << std::setfill('=') << std::setw(60) << "\n";
  st->dump();
  return 0;
}