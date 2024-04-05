all :
	lex lexer.l && yacc -d structfe.y && gcc -g -o structit y.tab.c lex.yy.c data_structure.c -ll

yacc:
	yacc -d structfe.y

lex:
	lex lexer.l

clean :
	rm -f structit

re : clean all