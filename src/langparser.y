%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();

/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var	// a variable
{
	char *name;
	int value;
	struct var *next;
} var;

typedef var *varlist;

typedef struct expr
{
	int type;
	expr *left, *right;
	int value;
} expr;

typedef struct stmt
{
	int type;
	var *var;
	expr *expr;
	varlist *varlist;
	stmt *next;
} stmt;

typedef stmt *stmtlist;

typedef struct proc
{
	char *name;
	varlist *vars;
	stmtlist *stmts;
} proc;

typedef struct proclist
{
	proc *proc;
	struct proclist *next;
} proclist;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *program_vars;
stmt *program_stmts;

/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var* make_ident (char *s)
{
	var *v = malloc(sizeof(var));
	v->name = s;
	v->value = 0;	// make variable false initially
	v->next = NULL;
	return v;
}

var* find_ident (char *s)
{
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

varlist* make_varlist (char *s)
{
	var *v = find_ident(s);
	varlist *l = malloc(sizeof(varlist));
	l->var = v;
	l->next = NULL;
	return l;
}

stmtlist* make_stmtlist (stmt s)
{
	stmtlist *l = malloc(sizeof(varlist));
	l->stmt = s;
	l->next = NULL;
	return l;
}


%}

/* types used by terminals and non-terminals */

%union {
	char *i;
	int *n;
	var *v;
	varlist *l;
	expr *e;
	stmt *s;
	stmtlist *sl;
	guard *g;
	guardlist *gl;
	proc *p;
	proclist *pl;
	reach *r;
	reachlist *rl;
}

%type <v> declist
%type <l> varlist
%type <e> expr
%type <s> stmt assign
%type <sl> stmtlist
%type <g> guard
%type <gl> guardlist
%type <p> proc
%type <pl> proclist
%type <r> reach
%type <rl> reachlist

%token VAR COMMA SEMICOLON PROC END IF FI DO OD GUARD ARROW ELSE SKIP REACH BREAK ASSIGN PLUS MINUS TIMES DIV MOD OR AND NOT EQUALS GT GTE LT LTE NOTEQUALS

%token <n> INT

%token <i> IDENT

%left ';'

%left OR 
%left AND
%right EQUALS
%right NOTEQUALS
%right NOT

%%

prog : declist proclist reachlist {}


declist : 
		| decl {}
 		| decl declist

decl : VAR varlist SEMICOLON {}

varlist : IDENT {}
  | IDENT COMMA varlist {}

expr : IDENT {}
	 | INT {}
	 | expr OR expr {}
	 | expr AND expr {}
	 | expr EQUALS expr {}
	 | expr NOTEQUALS expr {}
	 | NOT expr {}
	 | '(' expr ')' {}
	 | expr PLUS expr {}
	 | expr MINUS expr {}
	 | expr TIMES expr {}
	 | expr MOD expr {}
	 | expr DIV expr {}
	 | expr GT expr {}
	 | expr GTE expr {}
	 | expr LT expr {}
	 | expr LTE expr {}

assign : IDENT ASSIGN expr {}

stmt : assign {}
	 | stmt SEMICOLON stmt {}
	 | DO guardlist OD {}
	 | IF guardlist FI {}

proclist : proc {}
		 | proc proclist {}

proc : PROC declist stmtlist END {}

stmtlist : stmt {}
		 | stmt SEMICOLON stmtlist {}

guardlist : guard {}
		  | guard guardlist

guard : GUARD expr ARROW stmtlist

reach : REACH expr

reachlist : //empty
		  | reach
		  | reach reachlist

%%

#include "langlex.c"
