%option noyywrap

DIG	[0-9]
ALPHANUM [a-zA-Z0-9]

%%

"bool"	{ return BOOL; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"od"	{ return OD; }
"print"	{ return PRINT; }
"true"	{ return TRUE; }
"false"	{ return FALSE; }

":="	{ return ASSIGN; }
"^"	{ return XOR; }
"||"	{ return OR; }
"&&"	{ return AND; }
"!"	{ return NOT; }
"<=>" { return EQUIV; }

[a-z_][a-z0-9_]* { yylval.i = strdup(yytext); return IDENT; }

[	 \n]   { /* ignore */ }

.	{ return *yytext; }

%%

