all :
	lex lexer.l && yacc -d structfe.y && gcc -Wall -Wextra -g -o structit y.tab.c lex.yy.c data_structure.c -ll

yacc:
	yacc -d structfe.y

lex:
	lex lexer.l

clean :
	rm -f structit

test : all
	@bash ./test.sh
re : clean all
