%{
#include "type.hh"
#include "colorized.hh"
#include "symbolTable.hh"
#include "scanner.hh"

#define IS_SAME(a, b) (strcmp((a), (b)) == 0)
#define SCAN buf += (yytext)
#define MAX_LINE_LENG 256

int linenum = 1;
extern char* yytext;
SymbolTable st;
std::string buf = "";
std::string declType = "";
bool lexHint = false;
bool tokenFlow = false;

void token(std::string&& token, std::string desc)
{
  if(lexHint)
  {
    std::cout << "<";
    std::cout << std::left << std::setfill(' ') << std::setw(20) << ("'" + token + "'");
    std::cout << " : " << desc << "> \n";
  }
}

void newLineDetect(std::string& buf)
{
  bool isEmpty = std::all_of(buf.cbegin(), buf.cend(), [](auto& ch) {
    return ch == ' ' | ch == '\r' | ch == '\n' | ch == '\t';
  });
  std::string output = isEmpty ? cyan("<EMPTY>") + "\n" : buf;
  reset();
  if(tokenFlow)
  {
    std::cout << "line "
              << std::right << std::setfill('0') << std::setw(2) << linenum << " :"
              << output ;
  }
  linenum++;
  buf.clear();
}

%}

%option noyywrap
%option yylineno

%x COMMENT_STATE

multiCommentStart \/\*
multiCommentEnd \*\/
signalComment \/\/[^\n]*
comment       \/\/.*\n

arrow     ->

comma     ,
colon     :
semi      ;
lParent   \(
rParent   \)
lsBrack   \[
rsBrack   \]
lBrack    \{
rBrack    \}
delimiter {comma}|{colon}|{semi}|{lParent}|{rParent}|{lsBrack}|{rsBrack}|{lBrack}|{rBrack}

digit      [0-9]
integer    (\+|\-)?{digit}+
real       (\+|\-)?{integer}\.{integer}
scientific {integer}e(\+|\-)?{integer}
number     {real}|{scientific}|{integer}

identifier {alpha}({alpha}|{digit})*
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
loops     while|for|break|continue|in|\.\.
type      bool|boolean|string|int|integer|float
stmtkey   print|println|read|return

newline (\r)*\n(\r)*
space   [ \t]*

%%
{boolean}    {
  SCAN;
  token(id(yytext), "BOOL");
  yylval.context.first = yytext;
  yylval.context.second = T_BOOL;
  return BOOL_VALUE;
}

{integer} {
  SCAN;
  token(id(yytext), "NUMBER");
  yylval.context.first = yytext;
  yylval.context.second = T_INT;
  return INT_VALUE;
}

{real} {
  SCAN;
  token(id(yytext), "NUMBER");
  yylval.context.first = yytext;
  yylval.context.second = T_FLOAT;
  return FLOAT_VALUE;
}

{scientific} {
  SCAN;
  token(id(yytext), "NUMBER");
  yylval.context.first = yytext;
  yylval.context.second = T_FLOAT;
  return FLOAT_VALUE;
}

{string}  {
  buf += yytext;
  auto literalValue = std::string(yytext).substr(1, strlen(yytext)-2);
  while(literalValue.find("\"\"") != std::string::npos) {
    literalValue.replace(literalValue.find("\"\""), 2, "\"");
  }
  token(id(literalValue.c_str()), "STRING");
  yylval.context.first = literalValue;
  yylval.context.second = T_STRING;
  return STRING_VALUE;
}

{type} {
  SCAN;
  token(symbol(yytext), "KEYWORD");
  if( IS_SAME(yytext, "bool") || IS_SAME(yytext, "boolean") )
    return BOOL;
  if( IS_SAME(yytext, "int") || IS_SAME(yytext, "integer") ) 
    return INT;
  if( IS_SAME(yytext, "float") ) 
    return FLOAT;
  if( IS_SAME(yytext, "string") ) 
    return STRING;
}

{arithmetic} {
  SCAN;
  token(operators(yytext), "CALCULATE");
  return *yytext;
}

{delimiter} {
  SCAN;
  token(symbol(yytext), "SYMBOL");
  return *yytext;
}

{assignment} { SCAN; token(operators(yytext), "ASSIGN"); return '='; }
{lt}  { SCAN; token(operators(yytext), "$LT");  return LT;  }
{lte} { SCAN; token(operators(yytext), "$LTE"); return LTE; }
{gt}  { SCAN; token(operators(yytext), "$GT");  return GT;  }
{gte} { SCAN; token(operators(yytext), "$GTE"); return GTE; }
{eq}  { SCAN; token(operators(yytext), "$EQ");  return EQ;  }
{ne}  { SCAN; token(operators(yytext), "$NE");  return NE;  }

"val"|"var" {
  SCAN;
  token(keyword(yytext), "KEYWORD");
  declType = (IS_SAME(yytext, "var")) ? "variable" : "const variable";
  return (IS_SAME(yytext, "var")) ? VAR : VAL;
}

"fun"|"class" {
  SCAN;
  token(keyword(yytext), "KEYWORD");
  declType = (strcmp(yytext, "class") == 0) ? "class" : "function";
  return IS_SAME(yytext, "fun") ? FUN : CLASS;
}

{loops} {
  SCAN;
  token(keyword(yytext), "KEYWORD");
  if( IS_SAME(yytext, "while") ) return WHILE;
  if( IS_SAME(yytext, "for") ) return FOR;
  if( IS_SAME(yytext, "break") ) return BREAK;
  if( IS_SAME(yytext, "continue") ) return CONTINUE;
  if( IS_SAME(yytext, "in") ) return IN;
  if( IS_SAME(yytext, "..") ) return RANGE;
}

{condition} {
  SCAN;
  token(keyword(yytext), "KEYWORD");
  if( IS_SAME(yytext, "if") ) return IF;
  if( IS_SAME(yytext, "else") ) return ELSE;
  if( IS_SAME(yytext, "case") ) return CASE;
}

{stmtkey} {
  SCAN;
  token(keyword(yytext), "KEYWORD");
  if( IS_SAME(yytext, "print")) return PRINT;
  if( IS_SAME(yytext, "println")) return PRINTLN;
  if( IS_SAME(yytext, "read")) return READ;
  if( IS_SAME(yytext, "return")) return RETURN;
}

{identifier} { 
  SCAN; 
  token(id(yytext), "IDENTIFIER");
  yylval.context.first = yytext;
  yylval.context.second = 0;
  return IDENTIFIER;
}

{signalComment} {
  buf += comment(yytext);
}

{multiCommentStart} {
  buf += YELLOW;
  buf += yytext;
  BEGIN(COMMENT_STATE);
}

<COMMENT_STATE>{multiCommentEnd} {
  buf += comment(yytext);
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

{space}     {
  SCAN;
}

.           {
  std::cout << "line " << linenum <<":" << buf.size()+1 << " " << buf;
  std::cout << "\nbad character: '" << yytext << "'" << '\n';
  exit(-1);
}

<COMMENT_STATE>. {
  buf += yytext;
}

%%
