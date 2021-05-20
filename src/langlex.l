%option noyywrap
%option yylineno

%{
#include <string.h>
#include <stdio.h>


%}


%%

"//"[^\n]*"\n" {} /* TODO pprint */

"var" {  return VAR;}
"," { return COMMA;}
";" { return SEMICOLON;}
"proc" {return PROC;}
"end" {return END;}
"if" {return IF;}
"fi" {return FI;}
"do" {return DO;}
"od" {return OD;}
"::" {return GUARD;}
"->" {return ARROW;}
"else" {return ELSE;}
"skip" {return SKIP;}
"reach" {return REACH;}
"break" {return BREAK;}
":=" {return ASSIGN;}
"+" {return PLUS;}
"-" {return MINUS;}
"*" {return TIMES;}
"/" {return DIV;}
"%" {return MOD;}
"||" {return OR;}
"&&" {return AND;}
"!" {return NOT;}
"==" {return EQUALS;}
">" {return GT;}
">=" {return GTE;}
"<" {return LT;}
"<=" {return LTE;}
"!=" {return NOTEQUALS;}
"(" {return LP;}
")" {return RP;}

[0-9]+ {yylval.n = atoi(yytext) ; return INT;}  

[a-zA-Z_][a-zA-Z0-9_]* { yylval.i = strdup(yytext); return IDENT; }

[	 \n]   { /* ignore */ }

.	{ return *yytext; }

%%
