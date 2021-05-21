%{

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h>
#include <string.h>

#define N 100
#define PRECISION 100

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
  int n_instructions;
} proc;

typedef proc proclist;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *global_vars;
proc *procs;
reach *reaches;
int *reaches_value;


int get_rand(int n)
{
  return rand() % n;
}



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

proc* make_proc( char* name, varlist* vars, stmtlist* stmts, int instruction_number)
{
  proc* p = malloc(sizeof(proc));
	p->name = name;
	p->vars = vars;
	p->stmts = stmts;
  p->n_instructions = instruction_number;
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
	 | LP expr RP { $$ = make_expr(-1,$2,NULL,0,NULL); }

assign : IDENT ASSIGN expr {$$ = make_stmt(ASSIGN, $1, $3, NULL,  NULL);}

stmt : assign {$$ = $1; }
	 | DO guardlist OD { $$ = make_stmt(DO, NULL, NULL,  $2 , NULL);}
	 | IF guardlist FI { $$ = make_stmt(IF, NULL, NULL, $2 , NULL);}
   | BREAK { $$ = make_stmt(BREAK, NULL, NULL, NULL , NULL);}
   | SKIP { $$ = make_stmt(SKIP, NULL, NULL, NULL ,  NULL);}

proclist : proc {$$ = $1;}
		 | proc proclist {proc* proc_tmp = $1 ; proc_tmp->next = $2; $$ = proc_tmp; }

proc : PROC IDENT declist stmtlist END { $$ = make_proc($2,$3,$4,0); }
     | PROC IDENT stmtlist END { $$ = make_proc($2,NULL,$3,0); }

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
/********************* Pretty printer OBJ1 *************************/
void pprint_vars(var* var){
  if ( var != NULL){
    printf(" %s",var->name);
    pprint_vars(var->next);
  }
}

var* get_var(char* name, var* gvs, var* lvs);

void pprint_vars_with_value(var* var){
  if ( var != NULL){
    printf(" %s = %d ;",var->name, get_var(var->name, NULL , var)->value);
    pprint_vars_with_value(var->next);
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

/********************* Montecarlo OBJ2 *************************/
var* get_var(char* name, var* gvs, var* lvs)
{
  while(lvs != NULL){
    if( strcmp(lvs->name,name) == 0) return lvs;
    lvs = lvs->next;
  }
  while(gvs != NULL){
    if( strcmp(gvs->name,name) == 0) return gvs;
    gvs = gvs->next;
  }

  char* error;
  sprintf("Variable not declared : %s", name);
  
  yyerror(error);

  return NULL;
}

int eval(expr* expr, var* gvs, var* lvs)
{
  switch(expr->type){
    case IDENT : return get_var(expr->ident, gvs, lvs)->value;
    case INT : return expr->value;
    case OR : return eval(expr->left, gvs, lvs) || eval(expr->right, gvs, lvs);
    case AND : return eval(expr->left, gvs, lvs) && eval(expr->right, gvs, lvs);
    case EQUALS : return eval(expr->left, gvs, lvs) == eval(expr->right, gvs, lvs);
    case NOTEQUALS : return eval(expr->left, gvs, lvs) != eval(expr->right, gvs, lvs);
    case NOT : return !(eval(expr->left, gvs, lvs));
    case PLUS : return eval(expr->left, gvs, lvs) + eval(expr->right, gvs, lvs);
    case MINUS : return eval(expr->left, gvs, lvs) - eval(expr->right, gvs, lvs);
    case TIMES : return eval(expr->left, gvs, lvs) * eval(expr->right, gvs, lvs);
    case MOD : return eval(expr->left, gvs, lvs) % eval(expr->right, gvs, lvs);
    case DIV : return eval(expr->left, gvs, lvs) / eval(expr->right, gvs, lvs);
    case GT : return eval(expr->left, gvs, lvs) > eval(expr->right, gvs, lvs);
    case GTE : return eval(expr->left, gvs, lvs) >= eval(expr->right, gvs, lvs);
    case LT : return eval(expr->left, gvs, lvs) < eval(expr->right, gvs, lvs);
    case LTE : return eval(expr->left, gvs, lvs) <= eval(expr->right, gvs, lvs);
    default : return eval(expr->left, gvs, lvs);
  }
}

typedef struct context 
{
  stmt* stmt;
  struct context* next;
} context;

context* make_context(stmt* stmt, context* next)
{
  context* c = malloc(sizeof(context));
  c->stmt = stmt;
  c->next = next;
}

typedef struct simulation_struct
{
  stmt* stmt;
  context* context;
  var* gvs;
  var* lvs;
} simulation_struct;

simulation_struct* make_simulation_struct(stmt* stmt, context* context, var* gvs, var* lvs)
{
  simulation_struct* st = malloc(sizeof(simulation_struct));
  st->stmt = stmt;
  st->context = context;
  st->gvs = gvs;
  st->lvs = lvs;
  return st;
}

typedef struct guard_possibilities
{
  guard* guard;
  struct guard_possibilities* next;
}guard_possibilities;

guard_possibilities* make_guard_possibility(guard* guard, guard_possibilities* next)
{
  guard_possibilities* g = malloc(sizeof(guard_possibilities));
  g->guard = guard;
  g->next = next;
  return g;
}

int get_possibilities_size(guard_possibilities* poss);

guard_possibilities* suitable_guards(simulation_struct* st, guard* guards)
{
  guard_possibilities* res = NULL;
  int n_non_else = 0;
  int n_else = 0;
  while(guards != NULL)
  { 

    if(guards->guardexpr->is_else || eval(guards->guardexpr->expr, st->gvs, st->lvs))
    {
      res = make_guard_possibility(guards, res);
      if(!guards->guardexpr->is_else ){
        n_non_else += 1;
      }else{
        n_else += 1;
      }
    }
    guards = guards->next;    
  }
  if(n_non_else > 0 && n_else > 0){
    guard_possibilities* clean_res = NULL;
    while(res!= NULL){
      if( res->guard->guardexpr->is_else ){
        guard_possibilities* tmp = res->next;
        free(res);
        res = tmp;
      }else{
        guard_possibilities* tmp = res->next;
        res->next = clean_res;
        clean_res = res;
        res = tmp;
      }
    }

    return clean_res;
  }else{
    return res;
  }
}

void free_guard_possibilities(guard_possibilities* poss)
{
  if(poss == NULL) return;
  guard_possibilities* next = poss->next;
  free(poss);
  free_guard_possibilities(next);
}

int get_possibilities_size(guard_possibilities* poss)
{
  if(poss == NULL) return 0;

  return 1 + get_possibilities_size(poss->next);
}

stmt* get_guard(guard_possibilities* poss)
{
  int n = get_possibilities_size(poss);
  int roll = get_rand(n);
  for(int i = 0 ; i<roll ; i++){
    poss = poss->next;
  }
  return poss->guard->stmts;

}

void print_stmt_type(int type){
  switch(type){
    case BREAK: printf("TYPE BREAK"); return;
    case SKIP: printf("TYPE SKIP"); return;
    case ASSIGN: printf("TYPE ASSIGN"); return;
    case DO: printf("TYPE DO"); return;
    case IF: printf("TYPE IF"); return;
  }
}


typedef struct eligible_struct
{
  simulation_struct* st;
  struct eligible_struct *next;
} eligible_struct;

eligible_struct* make_eligible_struct(simulation_struct* st, eligible_struct* next)
{
  eligible_struct* es = malloc(sizeof(eligible_struct));
  es->st = st;
  es->next = next;
  return es;
}

eligible_struct* init_eligible_struct(proc* procs)
{
  eligible_struct* es = NULL;
  while(procs!=NULL)
  {
    eligible_struct* tmp = make_eligible_struct(make_simulation_struct(procs->stmts,NULL,global_vars,procs->vars), es);
    es = tmp;
    procs = procs->next;
  }
  return es;
}

int is_eligible(simulation_struct* st)
{
  if(st->stmt == NULL)
  {
    return 0;
  }
  switch(st->stmt->type)
  {
    case SKIP:  return 1;
    case BREAK:  return 1;
    case ASSIGN:  return 1;
    case DO:
    case IF: ; 
      guard_possibilities* tmp = suitable_guards(st, st->stmt->guards);
      if( tmp != NULL){
        free_guard_possibilities(tmp);
        return 1;
      }else{
        free_guard_possibilities(tmp);
        return 0;
      }
  }
}

typedef struct eligible_struct_chain
{ 
  eligible_struct* es;
  struct eligible_struct_chain* next;
} eligible_struct_chain;

void free_eligibles(eligible_struct_chain* eligibles)
{
  if(eligibles == NULL) return;
  eligible_struct_chain* next = eligibles->next;
  free(eligibles);
  free_eligibles(next);
}

eligible_struct_chain* make_eligible_struct_chain(eligible_struct* es, eligible_struct_chain* next)
{
  eligible_struct_chain* esc = malloc(sizeof(eligible_struct_chain));
  esc->es = es;
  esc->next = next;
  return esc;
}

eligible_struct_chain* get_eligible_structs(eligible_struct* ess)
{
  eligible_struct_chain* res = NULL;
  while(ess != NULL)
  {
    if( is_eligible(ess->st)){
      eligible_struct_chain* tmp = make_eligible_struct_chain(ess,res);
      res = tmp;
    }
    ess = ess->next;
  }
  return res;
}

int eligible_structs_size(eligible_struct_chain* esc)
{
  if(esc == NULL) return 0;

  return 1 + eligible_structs_size(esc->next);
}

eligible_struct* elect(eligible_struct_chain* esc)
{
  
  int n = eligible_structs_size(esc);
  int roll = get_rand(n);
  for(int i = 0 ; i<roll ; i++){
    esc = esc->next;
  }
  return esc->es;

}

void correct_links(stmt* stmts, stmt* correct_next, stmt* do_stmt);

void correct_links_if(stmt* if_stmt, stmt* do_stmt)
{
  guard* guards = if_stmt->guards;

  while(guards != NULL)
  {
    correct_links(guards->stmts, if_stmt->next , do_stmt );
    guards = guards->next;
  }
}

void correct_links_do(stmt* do_stmt)
{
  guard* guards = do_stmt->guards;

  while(guards != NULL)
  {
    correct_links(guards->stmts, do_stmt , do_stmt );
    guards = guards->next;
  }
}

void correct_links(stmt* stmts, stmt* correct_next, stmt* do_stmt)
{
  int stop = 0;
  while(stmts != NULL && !stop )
  {
    if(stmts->next == NULL)
    {
      stmts->next = correct_next;
      stop = 1;
    }

    if(stmts->type == IF)
    {
      correct_links_if( stmts , do_stmt);
      stmt* tmp = stmts;
      stmts = stmts->next;
      tmp->next = NULL;
    }else if(stmts->type == DO && stmts == do_stmt){
      stmts = stmts->next;
    }else if(stmts->type == DO)
    {
      correct_links_do( stmts);
      stmt* tmp = stmts;
      stmts = stmts->next;
      tmp->next = NULL;
    }else if (stmts->type == BREAK && do_stmt != NULL){
      stmts->next = do_stmt->next;
      //ajouter le free des stmts perdus
      break;
    }else{
      stmts =  stmts->next;
    }
  }
}

void correct_program(){
  proc* tmp = procs;
  while(tmp != NULL){
    correct_links(tmp->stmts, NULL, NULL);
    tmp = tmp->next;
  }
}

void goto_next(simulation_struct* st)
{
  st->stmt = st->stmt->next;
}

void print_debug(simulation_struct* st){
  printf("/****************** DEBUG START *******************/\n");
  if(st->stmt == NULL){
    printf("NULL \n NEXT -> NULL\n");
    return;
  }

  printf("{GLOBAL VARS :");
  pprint_vars_with_value(st->gvs);
  printf("}\n");
  printf("{LOCAL VARS :");
  pprint_vars_with_value(st->lvs);
  printf("}\n");
  print_stmt_type(st->stmt->type);
  if(st->stmt->type == ASSIGN){
    printf(" %s <- ", st->stmt->var);
    pprint_expr(st->stmt->expr);
  }
  printf("\nNEXT --> ");
  if(st->stmt->next == NULL){
    printf(" NULL");
  }else{
    print_stmt_type(st->stmt->next->type);
  }
  printf("\n");
  printf("/****************** DEBUG END *******************/\n");
}

void pprint_guarrds(  guard_possibilities* pguards   ){
  if(pguards == NULL)return ;
  printf("[");
  print_stmt_type(pguards->guard->stmts->type);
  printf("]\n");
  pprint_guarrds( pguards->next);
  
}

void execute_statement(simulation_struct* st){
  switch(st->stmt->type){
    case ASSIGN: 
      get_var(st->stmt->var,st->gvs,st->lvs)->value = eval(st->stmt->expr,st->gvs,st->lvs); 
    case SKIP:
    case BREAK:
      goto_next(st);  
      return;
    case DO:
    case IF: ; 
      guard_possibilities* pguards = suitable_guards(st,st->stmt->guards);
      if(pguards == NULL)
      {
        return;
      }else{
        st->stmt = get_guard(pguards);
        free_guard_possibilities(pguards);
        execute_statement(st);
        return;
      }
      
  }
}

int safe_increment(int n){
  if(n+1 == 0){
    return n+2;
  }else{
    return n+1;
  }
}

void check_reaches(){
  int i = 0;

  reach* reaches_tmp = reaches;

  while(reaches_tmp != NULL)
  {
    if(eval(reaches_tmp->expr,global_vars,NULL)){
      reaches_value[i] = safe_increment(reaches_value[i]);
    }
    i++;

    reaches_tmp = reaches_tmp->next;
  }
}

void interprete(int precision){
  int j = 0;
  eligible_struct* est = init_eligible_struct(procs);

  eligible_struct_chain* proc_choices = NULL;

  while( j < precision && (proc_choices= get_eligible_structs(est) ) != NULL ){
    check_reaches();
    eligible_struct* elected = elect(proc_choices);
    execute_statement(elected->st);
    free_eligibles(proc_choices);
    j++;
  }
  check_reaches();

}
void reset_vars(var* vars){
  if(vars == NULL) return;
  vars->value = 0;
  reset_vars(vars->next);
}

void reset_all_vars(){
  reset_vars(global_vars);
  proc* tmp = procs;
  while(tmp != NULL){
    reset_vars(tmp->vars);
    tmp = tmp->next;
  }
}

int reaches_size(reach* reaches){
  if(reaches==NULL) return 0;
  return 1 + reaches_size(reaches->next);
}

void montecarlo(int n, int precision){
  int i = 0;
  int n_reaches = reaches_size(reaches);
  reaches_value = malloc(sizeof(int)*n_reaches); 
  while(i < n)
  {
    int r_prec = (rand()%precision)+precision;
    reset_all_vars();
    interprete( r_prec ); 
    i++;
  }
  
  for(int j = 0; j < n_reaches ; j++)
  {
    printf("REACH %d -> %d\n", j+1,reaches_value[j] );
  }
  free(reaches_value);
}


/* todo ajouter de la freeance si possible, si possible valgrind ok */


/********************** Main **********************/
int main (int argc, char **argv)
{
  srand(time(NULL));   
	
    int t = 0;
    int m = 0;
    int p = PRECISION;
    int n = N; 
    char* file = NULL;
    int opt;
    opterr = 0;

    while((opt = getopt(argc, argv, "tmf:p:n:")) != -1) 
    { 
        switch(opt) 
        { 
            case 't': 
                t = 1; break;
            case 'm': 
                m = 1; break;
            case 'p': 
                if(sscanf(optarg, "%d", &p) == 1)
                  break;
                else
                {
                  fprintf (stderr, "Option -p requires an integer argument.\n");
                  return 1;
                }
            case 'n': 
                if(sscanf(optarg, "%d", &n) == 1)
                  break;
                else
                {
                  fprintf (stderr, "Option -n requires an integer argument.\n");
                  return 1;
                }
            case 'f':
                file = optarg;
                break;
            default :
              if (optopt == 'f' || optopt == 'p' || optopt == 'n')
                fprintf (stderr, "Option -%c requires an argument.\n", optopt);
              else if (isprint (optopt))
                fprintf (stderr, "Unknown option `-%c'.\n", optopt);
              else
                fprintf (stderr,
                         "Unknown option character `\\x%x'.\n",
                         optopt);
              return 1;
        } 
    }

  if(file == NULL){
    fprintf (stderr, "A file must be specified using -f .\n", optopt);
    return 1;
  }
	yyin = fopen(file,"r");

	if( !yyparse()){
    

    if(!t && !m) t = 1;

    if(t) pprint_prog();
    if(m)
    {
      correct_program();
      montecarlo(n, p);
    }
  }
}
