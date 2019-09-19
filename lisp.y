%{
#include "lisp.h"
extern "C"{
	extern int yylex(void);
	void yyerror(const char *s);
} 
stack<char> operators;
%}
%left PLS '-'
%left MPLY '/' 
%token <n> NUMBER 
%token <str> PLS MPLY PRTNUM DEFINE FUN MOD IF PRTBOOL
%token <n> CMP EQL LOG 
%token <s> ID
%type <a> exp explist plus minus numop multiply divide funbody
%type <a> funcall modulus cmp equal ifexp logop funexp
%type <sl> idlist funid 
%type <n> line program
%type <pl> PARAM
%%
program : 	line 
		|	program line 
		;
line	:	exp	{;}
		|	'(' PRTNUM exp ')'	{cout << eval($3) << endl;}
		|	'(' PRTBOOL exp ')'	
			{
				if(eval($3) != 0) cout << "#t" << endl;	
				else cout << "#f" << endl;
			} 
		|	defstmt	{;}
		;	
defstmt	:	'(' DEFINE ID exp ')'	{originaldef($3,$4);}
		;

explist	:	exp 		{ $$ = $1;}
		|	explist exp {$$ = newast('L',$2, $1);}
		;
exp		:	numop	{ $$ = $1;}
		|	logop	{ $$ = $1;}
		|	funcall	{ $$ = $1;}
		|	funexp	{ $$ = $1;}
		|	ifexp	{ $$ = $1;}
		|	ID 		{ $$ = newID($1);}
		|	NUMBER	{ $$ = newnum($1);}
		;
numop	:	plus		{ $$ = $1;}
		|	minus		{ $$ = $1;}
		|	multiply	{ $$ = $1;}
		|	divide		{ $$ = $1;}
		|	modulus		{ $$ = $1;}
		|	cmp			{ $$ = $1;}
		|	equal		{ $$ = $1;}	
		;
plus	:	'(' PLS explist exp ')'		{$$ = newast('+',$3,$4);}
		;
minus	:	'(' '-' exp exp ')' 		{$$ = newast('-',$3,$4);}
		;
multiply:	'(' MPLY explist exp ')' 	{$$ = newast('*',$3,$4);}
		;
divide	:	'(' '/' exp exp ')' 		{$$ = newast('/',$3,$4);}
		;
modulus :	'(' MOD exp exp ')'			{$$ = newast('%',$3,$4);}
cmp 	:	'(' CMP exp exp ')'			{$$ = newast($2,$3,$4);}
equal   :	'(' EQL explist exp ')'		{$$ = newast($2,$3,$4);}
logop	:	'(' LOG explist exp ')'		{$$ = newast($2,$3,$4);}
		|	'(' LOG exp ')'				{$$ = newast($2,$3,NULL);}
		;
funexp	:	'('FUN funid funbody ')' 	{$$ = newdef($3,$4);} 
		;
funid	:	'(' ')'			{ $$ = NULL;}
		|	'(' idlist ')'  { $$ = $2;} 
		;
funbody :	defstmt exp { $$ = $2;}  //nested
		|	exp 		{ $$ = $1;}
		;
idlist	:	ID 		  { $$ = newsymbole($1,NULL);}
		|	ID idlist { $$ = newsymbole($1,$2);}
		;		
funcall :	'(' funexp ')'			{$$ = newcall($2,NULL);}
		|	'(' ID ')'				{$$ = newnamedcall($2,NULL);}
		|	'(' funexp PARAM ')'	{$$ = newcall($2,$3);}
		|	'(' ID PARAM ')'		{$$ = newnamedcall($2,$3);}
		;
PARAM	:exp		{$$ = newparameter($1,NULL);}
		|exp PARAM	{$$ = newparameter($1,$2);}
		;
ifexp	:	'(' IF exp exp exp ')'		{$$ = newif($3,$4,$5);}
%%
void yyerror (const char *message){
    printf ("%s\n",message);
    exit(0);
}
ast* newast(int nodetype, ast*l, ast*r){
	ast* a = (ast*) malloc(sizeof(ast));
	a->nodetype = nodetype;
	a->l = l;
	a->r = r;
	if( a->l && a->l->nodetype == 'L'){
		a->l->parent = a;
	}
	if( a->r && a->r->nodetype == 'L'){
		a->r->parent = a;
	}
	return a;
}
ast* newnum(int n){
	numval* a = (numval*) malloc(sizeof(numval));
	a->nodetype = 'M';
	a->number = n;
	return (ast*) a;
}
ast* newif(ast*cond,ast* iftrue, ast*iffalse){
	ifval* a = (ifval*) malloc(sizeof(ifval));
	a->nodetype = 'I';
	a->cond = cond;
	a->iftrue = iftrue;
	a->iffalse = iffalse;
	return (ast*)a;	
}
ast* newnamedcall( symbol* f, pmlist* l){	
	namedcall* n = (namedcall*) malloc(sizeof(namedcall));
	n->nodetype = 'F';
	pmlist* tmp = l;
	while(tmp){
		ast* d = tmp->a;
		f->func = ((fnexp*)d)->func;
		f->syms = ((fnexp*)d)->syms;			
		l = tmp->next;
		tmp = tmp->next;
	}
	n->name = f; //funname
	n->pl = l;  //parameter
	free(tmp);
	return (ast*)n;
}
ast* newdef(symlist* syms, ast* func){  //define 
	fnexp* a = (fnexp*)malloc(sizeof(fnexp));
	a->nodetype = 'D';
	a->syms = syms;
	a->func = func;	
	return (ast*)a;
}
ast* newcall(ast* f, pmlist *l){
	call* a = (call*) malloc(sizeof(call));
	a->nodetype = 'C';
	a->func = ((fnexp*)f)->func;
	a->syms = ((fnexp*)f)->syms;
	a->pl = l;
	return (ast*)a;
}
ast* newID(symbol* s){ 							//ID
	symval* a = (symval*)malloc(sizeof(symval));
	a->nodetype = 'N';
	a->s = s;
	return (ast*)a;
}
symlist* newsymbole(symbol* sym, symlist*next){   //more than one ID
	symlist* sl = (symlist*) malloc(sizeof(symlist));
	sl->sym = sym;
	sl->next = next;
	return sl;
}
pmlist* newparameter(ast* l, pmlist*next){     // more than one parameter in function
	pmlist* pl = (pmlist*)malloc(sizeof(pmlist));
	pl->a = l;
	pl->next = next;
	return pl;
}
void originaldef(symbol* name, ast* d){
	if(d->nodetype == 'D'){
		name->func = ((fnexp*)d)->func;
		name->syms = ((fnexp*)d)->syms;
	}
	if(d->nodetype == 'F'){
		ast* t = ((namedcall*)d)->name->func;
		name->func = ((fnexp*)t)->func;
		name->syms = ((fnexp*)t)->syms;
	}
	else
		name->value = eval(d);
}
int evalfunction(ast* fn, symlist* osl, pmlist* params){
	if(!params){
		return eval(fn);
	}
	symlist* sl = osl;
	pmlist* pms = params;
	int *newval, num_arg; //argument 個數

	for(num_arg = 0; sl; sl= sl->next)
		num_arg++;
	newval = (int*)malloc(num_arg * sizeof(int));
	//運算新參數的數值
	for(int i = 0; i < num_arg; i++){
		newval[i] = eval(pms-> a);
		pms = pms-> next;		
	}
	return eval(fn);
}

int eval(ast*a){
	int v;
	switch(a->nodetype){
	case '+': v = eval(a->l) + eval(a->r); break;
	case '*': v = eval(a->l) * eval(a->r); break;
	case '-': v = eval(a->l) - eval(a->r); break;
	case '/': v = eval(a->l) / eval(a->r); break;
	case '%': v = eval(a->l) % eval(a->r); break;

	case '1': v = (eval(a->l) < eval(a->r))? 1 : 0; break;
	case '2': v = (eval(a->l) > eval(a->r))? 1 : 0; break;
	case '3': v = (eval(a->l) == eval(a->r))? 1 : 0; break;
	case '4': v = (eval(a->l) || eval(a->r))? 1 : 0; break;
	case '5': v = (eval(a->l) && eval(a->r))? 1 : 0; break;
	case '6': v = (eval(a->l) == 0)? 1 : 0; break;
	
	case 'L': 
		{
			ast* prnt = a->parent;			
			while(prnt->nodetype == 'L')
				prnt = prnt->parent;
						
			int l = eval(a->l);
			int r = eval(a->r);		
			if(prnt->nodetype == '+')
				v = l+r;
			if(prnt->nodetype == '*')
				v = l*r;
			if(prnt->nodetype == '=')
				v = (r == l)?1:0;
			if(prnt->nodetype == '4')
				v = (r || l)? 1: 0;
			if(prnt->nodetype == '5')
				v = (r && l)? 1 : 0;						
			break;
		}
	case 'I': //if
		{	
			if(eval(((ifval*)a)->cond) != 0)	
				v = eval(((ifval*)a)->iftrue);
			else			
				v = eval(((ifval*)a)->iffalse);
			break;
		}
	case 'F': //function
		{
			v = evalfunction(((namedcall*)a)->name->func,((namedcall*)a)->name->syms,((namedcall*)a)->pl);
			break; //function(變數運算),funname(變數),parameter
		}
	case 'C':
		{
			v = evalfunction(((call*)a)->func,((call*)a)->syms,((call*)a)->pl);
			break; //function(變數運算),funname(變數),parameter
		}

	case 'N': v = ((symval*)a)->s->value;break; //ID
	case 'M': v = ((numval*)a)->number;break;  //number
	}
	return v;
}
int main(int argc, char * argv[]){
	yyparse();
	return 0;
}