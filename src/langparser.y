%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();

void yyerror(char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}

/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var	// a variable
{
	char *name;
	int value;
	struct var *next;
} var;

typedef var varlist;

typedef struct expr
{
	int type;
	struct expr *left, *right;
	int value;
  char* ident;
} expr;

typedef struct guard
{
  int fion;
} guard;

typedef guard guardlist;

typedef struct reach
{
  int anal;
} reach;

typedef reach reachlist;

typedef struct stmt
{
	int type;
	var *var;
	expr *left;
	expr *right;
	varlist *varlist;
	struct stmt *next;
  guardlist *guards;
} stmt;

typedef stmt stmtlist;

typedef struct proc
{
	char *name;
	varlist *vars;
	stmtlist *stmts;
  struct proc* next;
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

/* TODO arrêter de se lébran et corriger ça
var* find_ident (char *s)
{
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}
*/

expr* make_expr( int type , expr* left, expr* right, int value, char* ident)
{
  expr* e = malloc(sizeof(expr));
  e->type = type;
  e->left = left;
  e->right = right;
  e->ident = ident;
  e->value = value;
  return e;
}

proc* make_proc( char* name, varlist* vars, stmtlist* stmts)
{
  proc* p = malloc(sizeof(proc));
	p->name = name;
	p->vars = vars;
	p->stmts = stmts;
  return p;
}

stmt* make_stmt( int type, var* var, expr* left, expr* right, varlist* varlist, stmt* next, guardlist* guards)
{
  stmt* s = malloc(sizeof(stmt));
	s->type = type;
	s->var = var;
	s->left = left;
	s->right = right;
	s->varlist = varlist;
	s->next = next;
  s->guards = guards;
  return s;
}



%}

/* types used by terminals and non-terminals */

%union {
	char *i;
	int n;
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

%left SEMICOLON
%left OR AND
%left EQUALS NOTEQUALS
%left GTE GT LTE LT
%right PLUS MINUS
%left TIMES DIV MOD
%right NOT

%%

prog : declist proclist reachlist {}
     | proclist reachlist {}
     | declist proclist  {}
     | proclist {}


declist : decl {}
 		| decl declist

decl : VAR varlist SEMICOLON {}

varlist : IDENT {}
  | IDENT COMMA varlist {}

expr : IDENT {$$ = make_expr(IDENT,NULL,NULL,NULL,$1); }
	 | INT {$$ = make_expr(INT,NULL,NULL,$1,NULL); }
	 | expr OR expr { $$ = make_expr(OR,$1,$3,0,NULL); }
	 | expr AND expr { $$ = make_expr(AND,$1,$3,0,NULL); }
	 | expr EQUALS expr { $$ = make_expr(EQUALS,$1,$3,0,NULL); }
	 | expr NOTEQUALS expr { $$ = make_expr(NOTEQUALS,$1,$3,0,NULL); }
	 | NOT expr { $$ = make_expr(NOT,$2,NULL,0,NULL); }
	 //| '(' expr ')' {}
	 | expr PLUS expr { $$ = make_expr(PLUS,$1,$3,0,NULL); }
	 | expr MINUS expr { $$ = make_expr(MINUS,$1,$3,0,NULL); }
	 | expr TIMES expr { $$ = make_expr(TIMES,$1,$3,0,NULL); }
	 | expr MOD expr { $$ = make_expr(MOD,$1,$3,0,NULL); }
	 | expr DIV expr { $$ = make_expr(DIV,$1,$3,0,NULL); }
	 | expr GT expr { $$ = make_expr(GT,$1,$3,0,NULL); }
	 | expr GTE expr { $$ = make_expr(GTE,$1,$3,0,NULL); }
	 | expr LT expr { $$ = make_expr(LT,$1,$3,0,NULL); }
	 | expr LTE expr { $$ = make_expr(LTE,$1,$3,0,NULL); }

assign : IDENT ASSIGN expr {$$ = make_stmt(ASSIGN, $1, $3, NULL, NULL, NULL, NULL);}

stmt : assign {$$ = $1; }
	 | stmt SEMICOLON stmt { $$ = make_stmt(SEMICOLON, NULL, $1, $3, NULL, NULL, NULL);}
	 | DO guardlist OD { $$ = make_stmt(DO, NULL, NULL, NULL, NULL, NULL, $2);}
	 | IF guardlist FI { $$ = make_stmt(IF, NULL, NULL, NULL, NULL, NULL, $2);}

proclist : proc {$$ = $1;}
		 | proc proclist {proc* proc_tmp = $1 ; proc_tmp->next = $2; $$ = proc_tmp; }

proc : PROC IDENT declist stmtlist END {
      $$ = make_proc($2,$3,$4);
     }
     | PROC IDENT stmtlist END {
      $$ = make_proc($2,NULL,$3);
     }

stmtlist : stmt {}
		 | stmtlist SEMICOLON stmtlist {}

guardlist : guard {}
		  | guard guardlist {}

guard : GUARD expr ARROW stmtlist {}

reach : REACH expr {}

reachlist : reach {}
		  | reach reachlist {}

%%

#include "langlex.c"

int main (int argc, char **argv)
{
  return 0;
}
