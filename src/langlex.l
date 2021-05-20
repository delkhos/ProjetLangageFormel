%option noyywrap

DIG	[0-9]

%{
#include <string.h>

enum {
  VAR ,
  COMMA ,
  SEMICOLON ,
  PROC ,
  END ,
  IF ,
  FI ,
  DO ,
  OD ,
  GUARD ,
  ARROW ,
  ELSE ,
  SKIP ,
  REACH ,
  BREAK ,
  ASSIGN ,
  PLUS ,
  MINUS ,
  TIMES ,
  DIV ,
  MOD ,
  OR ,
  AND ,
  NOT ,
  EQUALS,
  GT ,
  GTE ,
  LT ,
  LTE ,
  NOTEQUALS,
  INT ,
  IDENT
};

union {
        int i;
        char *s;
} yylval; 
%}


%%

"//"[^\n]*"\n" {} /* TODO pprint */

"var" { return VAR;}
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

[DIG]+ {yylval.i = atoi(yytext) ; return INT;}  

[a-zA-Z_][a-zA-Z0-9_]* { yylval.s = strdup(yytext); return IDENT; }

[	 \n]   { /* ignore */ }

.	{ return *yytext; }

%%

int main()
{
        yylex();
        printf("\n");
}


