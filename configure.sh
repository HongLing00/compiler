#yacc compiler
bison -d lisp.y
g++ -c -g -I.. lisp.tab.c

#lex compiler
flex -o lisp.yy.c lisp.l
g++ -c -g -I.. lisp.yy.c

#compile and link bison and lex
g++ -o lisp lisp.tab.o lisp.yy.o -ll
