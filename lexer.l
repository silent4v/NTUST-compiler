%{
#include <string>
#include <algorithm>
#include <functional>
#include <cstdio>
#include <vector>
#include "colorized.hh"

#define MAX_LINE_LENG 256

int linenum = 1;

std::string buf = "";

void token(std::string&& token, std::string desc)
{
  printf("<'%s' : %s> \n", token.c_str(), desc.c_str());
}

%}

%option c++
%option noyywrap
%option yylineno
%option debug
%x COMMENT_STATE

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
  token(operators(YYText()), "arithmetic");
}

{assignment} {
  buf += YYText();
  token(operators(YYText()), "arithmetic");
}

{number}  {
  buf += YYText();
  token(id(YYText()), "number");
}

{string}  {
  buf += YYText();
  auto literalValue = std::string(YYText()).substr(1, strlen(YYText())-2);
  literalValue.replace(literalValue.find("\"\""), 2, "\"");
  token(id(literalValue.c_str()), "string");
}

{boolean} {
  buf += YYText();
  token(id(YYText()), "boolean");
}

{lt} {
  buf += YYText();
  token(operators(YYText()), "$lt");
}

{lte} {
  buf += YYText();
  token(operators(YYText()), "$lte");
}

{gt} {
  buf += YYText();
  token(operators(YYText()), "$gt");
}

{gte} {
  buf += YYText();
  token(operators(YYText()), "$gte");
}
{eq} {
  buf += YYText();
  token(operators(YYText()), "$eq");
}

{ne} {
  buf += YYText();
  token(operators(YYText()), "$ne");
}

{delimiter} {
  buf += YYText();
  token(symbol(YYText()), "symbol");
}

{keywords} {
  buf += YYText();
  token(keyword(YYText()), "keyword");
}

{identifier} {
  buf += YYText();
  token(id(YYText()), "identifier");
}

{signalComment} {
  buf += YELLOW;
  buf += YYText();
  buf += RESET;
}

{multiCommentStart} {
  buf += YELLOW;
  buf += YYText();
  BEGIN(COMMENT_STATE);
}

<COMMENT_STATE>{multiCommentEnd} {
  buf += YYText();
  buf += RESET;
  BEGIN(INITIAL);
}

{newline}   {
  buf += YYText();
  auto isEmpty = std::all_of(buf.cbegin(), buf.cend(), [](auto& ch) {
    return ch == ' ' | ch == '\r' | ch == '\n' | ch == '\t';
  });
  auto output = isEmpty ? std::string(CYAN) + "<EMPTY>" + RESET + "\n" : buf;
  printf("%sline %02d: %s\n", RESET, linenum, output.c_str());
  linenum++;
  buf = "";
}

<COMMENT_STATE>{newline} {
  buf += YYText();
  auto isEmpty = std::all_of(buf.cbegin(), buf.cend(), [](auto& ch) {
    return ch == ' ' | ch == '\r' | ch == '\n' | ch == '\t';
  });
  auto output = isEmpty ? std::string(CYAN) + "<EMPTY>" + RESET + "\n" : buf;
  printf("%sline %02d: %s\n", RESET, linenum, output.c_str());
  linenum++;
  buf = YELLOW;
}


{space}     {
  buf += YYText();
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
  return 0;
}