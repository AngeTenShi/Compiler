all :
	lex lexer.l && yacc -d structfe.y && gcc -g -o structit y.tab.c lex.yy.c data_structure.c traduction.c -ll # -Wall -Wextra -Werror if needed
yacc:
	yacc -d structfe.y

lex:
	lex lexer.l

clean :
	@rm -f structit

test : all
	@bash ./test.sh
re : clean all
