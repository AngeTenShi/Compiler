all :
	lex lexer.l && yacc -d structfe.y && gcc -o structit y.tab.c lex.yy.c -ll

clean :
	rm -f structit

re : clean all