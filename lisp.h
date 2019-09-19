#ifndef MAIN_HPP
#define MAIN_HPP

#include <iostream>
#include <vector>
#include <stdio.h>
#include <stack>
#include <cstdlib>
#include <string.h>
#include <map>
#include <string>
using namespace std;
struct ast{
	int nodetype;
	ast* l;
	ast* r;
	ast* parent = NULL;
};

struct symbol{
	char *name;
	int value;
	ast* func;
	struct symlist* syms;
};
struct symlist{
	symbol * sym;
	symlist* next;
};
struct fnexp{
	int nodetype;
	ast* func;
	symlist* syms;
};
struct pmlist{
	ast* a;
	pmlist* next;
};
struct namedcall{
	int nodetype; //F
	symbol* name;
	pmlist* pl;

};
struct call{
	int nodetype; //C
	ast*func;
	symlist* syms;
	pmlist* pl;
};
struct numval{
	int nodetype;
	int number;
};
struct symval{
	int nodetype;
	symbol* s;
};
struct ifval{
	int nodetype;
	ast* cond;
	ast* iftrue;
	ast* iffalse;
};

struct Type{
	int n;
	char* str;
	symbol *s;
	symlist *sl;
	pmlist *pl;
	ast* a;
	fnexp *fexp;
};
int eval(ast* a);
ast* newast(int nodetype, ast*l, ast*r);
ast* newID(symbol*s);
ast* newnum(int n);
ast* newdef(symlist* syms, ast* body);
ast* newif(ast*cond,ast* iftrue, ast*iffalse);
ast* newnamedcall( symbol* f, pmlist* l);
ast* newcall(ast* f, pmlist*l);
symlist* newsymbole(symbol* sym,symlist*next);
pmlist* newparameter(ast* l, pmlist*next);
void originaldef(symbol*name, ast* d);
int evalfunction(ast* fn , symlist*osl,pmlist* params);

#define YYSTYPE Type
#endif
