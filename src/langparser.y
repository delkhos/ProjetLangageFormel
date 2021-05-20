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

typedef struct reach
{
  expr* expr;
  struct reach* next;
} reach;

typedef reach reachlist;

struct guard;
typedef struct guard guardlist;

typedef struct stmt
{
	int type;
	char *var;
	expr *expr;
	struct stmt *next;
  guardlist *guards;
} stmt;

typedef stmt stmtlist;

typedef struct guardexpr
{
  int is_else;
  expr* expr;
} guardexpr;


typedef struct guard
{
  guardexpr* guardexpr;
  stmtlist *stmts;
  struct guard* next;
} guard;

typedef struct proc
{
	char *name;
	varlist *vars;
	stmtlist *stmts;
  struct proc* next;
} proc;

typedef proc proclist;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *global_vars;
proc *procs;
reach *reaches;

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

var* concat_decl (var* v1, var* v2)
{
  var* tmp = v1;
  while(tmp->next != NULL) tmp = tmp->next;
  tmp->next = v2;
  return v1;
}

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

stmt* make_stmt( int type, char* var, expr* expr,  guardlist* guards, stmt* next )
{
  stmt* s = malloc(sizeof(stmt));
	s->type = type;
	s->var = var;
	s->expr = expr;
	s->next = next;
  s->guards = guards;
  return s;
}


guard* make_guard(guardexpr* guardexpr, stmtlist *stmts, guard* next)
{
  guard* g = malloc(sizeof(guard));
  g->guardexpr = guardexpr;
  g->stmts = stmts;
  g->next = next;
  return g;
}

reach* make_reach(expr* expr, reach* next)
{
  reach* r = malloc(sizeof(reach));
  r->expr = expr;
  r->next = next;
  return r;
}

guardexpr* make_guardexpr(int is_else, expr* expr)
{
  guardexpr* g = malloc(sizeof(guardexpr));
  g->is_else = is_else;
  g->expr = expr;
  return g;
}




%}
%define parse.lac full
%define parse.error detailed
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
  guardexpr *ge;
	guardlist *gl;
	proc *p;
	proclist *pl;
	reach *r;
	reachlist *rl;
}

%type <v> declist
%type <l> varlist
%type <l> decl
%type <e> expr
%type <s> stmt assign
%type <sl> stmtlist
%type <g> guard
%type <ge> guardexpr
%type <gl> guardlist
%type <p> proc
%type <pl> proclist
%type <r> reach
%type <rl> reachlist

%token VAR COMMA SEMICOLON PROC END IF FI DO OD GUARD ARROW ELSE SKIP REACH BREAK ASSIGN PLUS MINUS TIMES DIV MOD OR AND NOT EQUALS GT GTE LT LTE NOTEQUALS RP LP

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

prog : declist proclist reachlist { global_vars = $1 ; procs = $2 ; reaches = $3;}
     | proclist reachlist {  procs = $1 ; reaches = $2;}
     | declist proclist  { global_vars = $1 ; procs = $2 ;}
     | proclist { procs = $1 ;}


declist : decl {$$ = $1; }
 		| decl declist {$$ = concat_decl($1, $2) ;}

decl : VAR varlist SEMICOLON { $$ = $2 ;}

varlist : IDENT { $$ = make_ident($1);}
  | IDENT COMMA varlist { var* var_tmp = make_ident($1) ; var_tmp->next = $3; $$ = var_tmp;   }

expr : IDENT {$$ = make_expr(IDENT,NULL,NULL,0,$1); }
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
	 | LP expr RP { $$ = make_expr(LTE,$2,NULL,0,NULL); }

assign : IDENT ASSIGN expr {$$ = make_stmt(ASSIGN, $1, $3, NULL,  NULL);}

stmt : assign {$$ = $1; }
	 | DO guardlist OD { $$ = make_stmt(DO, NULL, NULL,  $2 , NULL);}
	 | IF guardlist FI { $$ = make_stmt(IF, NULL, NULL, $2 , NULL);}
   | BREAK { $$ = make_stmt(BREAK, NULL, NULL, NULL , NULL);}
   | SKIP { $$ = make_stmt(SKIP, NULL, NULL, NULL ,  NULL);}

proclist : proc {$$ = $1;}
		 | proc proclist {proc* proc_tmp = $1 ; proc_tmp->next = $2; $$ = proc_tmp; }

proc : PROC IDENT declist stmtlist END { $$ = make_proc($2,$3,$4); }
     | PROC IDENT stmtlist END { $$ = make_proc($2,NULL,$3); }

stmtlist : stmt {$$ = $1;}
		 | stmt SEMICOLON stmtlist { stmt* stmt_tmp = $1 ; stmt_tmp->next = $3; $$ = stmt_tmp;  }

guardlist : guard {$$ = $1;}
		  | guard guardlist { guard* guard_tmp = $1 ; guard_tmp->next = $2; $$ = guard_tmp;  }

guardexpr: expr {$$ = make_guardexpr(0,$1);}
         | ELSE {$$ = make_guardexpr(1,NULL);}

guard : GUARD guardexpr ARROW stmtlist { $$ = make_guard($2,$4, NULL);}

reach : REACH expr {$$ = make_reach($2,NULL);}

reachlist : reach {$$ = $1;}
		  | reach reachlist { reach* reach_tmp = $1 ; reach_tmp->next = $2; $$ = reach_tmp;  }

%%

#include "langlex.c"
/********************* Pretty printer *************************/
void pprint_vars(var* var){
  if ( var != NULL){
    printf(" %s",var->name);
    pprint_vars(var->next);
  }
}

void print_indent(int n){
  for(int i = 0; i < n ; i++){
    printf("\t");
  }
}

void pprint_expr(expr* expr){
  if(expr == NULL) return;
  switch (expr->type){
    case IDENT: printf("%s",expr->ident); break;
    case INT: printf("%d",expr->value); break;
    case OR: printf("("); pprint_expr(expr->left); printf(") OR ("); pprint_expr(expr->right); printf(")"); break;
    case AND: printf("("); pprint_expr(expr->left); printf(") AND ("); pprint_expr(expr->right); printf(")"); break;
    case EQUALS: printf("("); pprint_expr(expr->left); printf(") EQUALS ("); pprint_expr(expr->right); printf(")"); break;
    case NOTEQUALS: printf("("); pprint_expr(expr->left); printf(") NOTEQUALS ("); pprint_expr(expr->right); printf(")"); break;
    case PLUS: printf("("); pprint_expr(expr->left); printf(") PLUS ("); pprint_expr(expr->right); printf(")"); break;
    case NOT: printf("NOT ("); pprint_expr(expr->left); printf(")"); break;
    case MINUS: printf("("); pprint_expr(expr->left); printf(") MINUS ("); pprint_expr(expr->right); printf(")"); break;
    case TIMES: printf("("); pprint_expr(expr->left); printf(") TIMES ("); pprint_expr(expr->right); printf(")"); break;
    case MOD: printf("("); pprint_expr(expr->left); printf(") MOD ("); pprint_expr(expr->right); printf(")"); break;
    case DIV: printf("("); pprint_expr(expr->left); printf(") DIV ("); pprint_expr(expr->right); printf(")"); break;
    case GT: printf("("); pprint_expr(expr->left); printf(") GT ("); pprint_expr(expr->right); printf(")"); break;
    case GTE: printf("("); pprint_expr(expr->left); printf(") GTE ("); pprint_expr(expr->right); printf(")"); break;
    case LT: printf("("); pprint_expr(expr->left); printf(") LT ("); pprint_expr(expr->right); printf(")"); break;
    case LTE: printf("("); pprint_expr(expr->left); printf(") LTE ("); pprint_expr(expr->right); printf(")"); break;
    default: printf("("); pprint_expr(expr->left); printf(")"); break;

  }

}

void pprint_guardexpr(guardexpr* guardexpr)
{
  if(guardexpr->is_else){
    printf("ELSE");
  }else{
    pprint_expr(guardexpr->expr);
  }
}

void pprint_stmts(stmt* stmt, int indent);

void pprint_guards(guard* guard, int indent){
  if(guard == NULL) return;
  print_indent(indent);
  printf("|START GUARD| : ") ; pprint_guardexpr(guard->guardexpr); printf(" ->\n");
  pprint_stmts(guard->stmts, indent + 1);
  print_indent(indent);
  printf("|END GUARD|\n");
  pprint_guards(guard->next, indent);

}


void pprint_stmts(stmt* stmt, int indent){
  if(stmt == NULL) return;
  print_indent(indent);
  switch (stmt->type)
  {
    case ASSIGN:
      printf("[ASSIGN : %s <- ", stmt->var); pprint_expr(stmt->expr); printf("]\n");
      break;
    case SKIP:
      printf("[SKIP]\n");
      break;
    case BREAK:
      printf("[BREAK]\n");
      break;
    case IF:
      printf("[IF :\n", stmt->var);
      pprint_guards(stmt->guards, indent+1);
      print_indent(indent);
      printf("FI]\n");
      break;
    case DO:
      printf("[DO :\n", stmt->var );
      pprint_guards(stmt->guards, indent+1);
      print_indent(indent);
      printf("OD]\n");
      break;
  }
  pprint_stmts(stmt->next, indent);
  
}

void pprint_procs(proc* proc){
  printf("{ PROC : %s\n", proc->name);
  printf("\t{ LOCAL VARS :");
  pprint_vars(proc->vars);
  printf("\t}\n");
  pprint_stmts(proc->stmts,1 );

  printf("}\n");
  if(proc->next != NULL){
    pprint_procs(proc->next);
  }

}

void pprint_reaches(reach* reach){
  if(reach == NULL) return;
  printf("{ REACH : "); pprint_expr(reach->expr); printf("}\n");
  pprint_reaches(reach->next);
}

void pprint_prog()
{
  printf("{GLOBAL VARS :");
  pprint_vars(global_vars);
  printf("}\n");
  pprint_procs(procs);
  pprint_reaches(reaches);

}



int main (int argc, char **argv)
{
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if( !yyparse()){
    pprint_prog();
  }
}
