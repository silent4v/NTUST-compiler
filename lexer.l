%{
#include <string>
#include <algorithm>
#include <functional>
#include <cstdio>
#include <vector>
#define MAX_LINE_LENG 256
#define GREEN   "\033[32m"
#define CYAN    "\033[36m"
#define RED     "\033[31m"
#define MAGENTA "\033[35m"
#define RESET   "\033[0m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
int linenum = 1;

bool ignoreFlag = false;
std::string buf = "";

std::string toUpper(const char* t) {
  std::string value(t);
  std::for_each(value.begin(), value.end(), [](auto& ch) {
    ch = toupper(ch);
  });
  return value;
}

void operators(const char* t, std::string operatorType)
{
  std::string value(t);
  std::for_each(value.begin(), value.end(), [](auto& ch) {
    ch = toupper(ch);
  });
  std::cout << "<'"
            << MAGENTA << value << RESET
            << "' : " << operatorType << ">\n";
}

void symbol(const char* t)
{
  auto value = toUpper(t);
  std::cout << "<'"
            << BLUE << value << RESET
            << "'>\n";
}

void keyWord(const char* t)
{
  auto value = toUpper(t);
  std::cout << "<'"
            << GREEN << value << RESET
            << "'>\n";
}

void tokenValue(const char* t, std::string value)
{
  std::cout << "<'"
            << RED << t << RESET
            <<  "' : " << value << ">\n";
}

%}

%option c++
%option noyywrap
%option yylineno
%option debug

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
sub     -
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
cSub     -=
cMul     \*=
cDiv     \/=
cOperator {cAdd}|{cSub}|{cMul}|{cDiv}

boolean   true|false
condition if|else|case
loops     loop|while|for|break|continue
declares  val|var|declare|class
type      bool|char|string|int|float
etc       do|exit|fun|print|println|return
keywords  {boolean}|{condition}|{loops}|{declares}|{type}|{etc}

identifier {alpha}({alpha}|{digit})*

newline (\r)*\n(\r)*
space   [ \t]*

%%

{arithmetic} {
  buf += YYText();
  if(!ignoreFlag) operators(YYText(), "arithmetic");
}

{assignment} {
  buf += YYText();
  if(!ignoreFlag) operators(YYText(), "assignment");
}

{number}  {
  buf += YYText();
  if(!ignoreFlag) {
    tokenValue(YYText(), "number");
  }
}

{string}  {
  buf += YYText();
  auto literalValue = std::string(YYText()).substr(1, strlen(YYText())-2);
  literalValue.replace(literalValue.find("\"\""), 2, "\"");
  if(!ignoreFlag) {
    tokenValue(literalValue.c_str(), "string");
  }
}

{boolean} {
  buf += YYText();
  if(!ignoreFlag) {
    tokenValue(YYText(), "boolean");
  }
}

{lt} {
  buf += YYText();
  if(!ignoreFlag) {
    operators(YYText(), "$lt");
  }
}
{lte} {
  buf += YYText();
  if(!ignoreFlag) {
    operators(YYText(), "$lte");
  }
}
{gt} {
  buf += YYText();
  if(!ignoreFlag) {
  operators(YYText(), "$gt");
  }
}
{gte} {
  buf += YYText();
  if(!ignoreFlag) {
    operators(YYText(), "$gte");
  }
}
{eq} {
  buf += YYText();
  if(!ignoreFlag) {
    operators(YYText(), "$eq");
  }
}
{ne} {
  buf += YYText();
  if(!ignoreFlag) {
    operators(YYText(), "$ne");
  }
}

{delimiter} {
  buf += YYText();
  if(!ignoreFlag) {
    symbol(YYText());
  }
}

{keywords} {
  buf += YYText();
  if(!ignoreFlag) {
    keyWord(YYText());
  }
}

{identifier} {
  buf += YYText();
  if(!ignoreFlag) {
    tokenValue(YYText(), "identifier");
  }
}

{signalComment} {
  buf += YELLOW;
  buf += YYText();
  buf += RESET;
}

{multiCommentStart} {
  ignoreFlag = true;
  buf += YELLOW;
  buf += YYText();
  buf += RESET;
}

{multiCommentEnd} {
  ignoreFlag = false;
  buf += YELLOW;
  buf += YYText();
  buf += RESET;
}

{newline}   {
  buf += YYText();
  auto empty = std::all_of(buf.begin(), buf.end(), [](auto& ch){
    return ch == ' ' || ch == '\n';
  });
  if(empty) {
    printf("line %02d: %s<EMPTY>%s\n\n", linenum, CYAN, RESET);
  } else {
    std::string colorize = (ignoreFlag ? YELLOW : RESET);
    printf("line %02d: %s%s%s\n", linenum, 
      (ignoreFlag ? YELLOW : RESET), buf.c_str(), RESET
    );
  }
  linenum++;
  buf = "";
}

{space}     {
  buf += YYText();
}

.           {
  if(ignoreFlag) {
    buf += YYText();
  } else {
    std::cout << "line " << linenum <<":" << buf.size()+1 << " " << buf;
    std::cout << "\nbad character: '" << YYText() << "'" << '\n';
    exit(-1);
  }
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
  return 0;
}