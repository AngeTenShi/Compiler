all :
	lex lexer.l && yacc -d structfe.y && gcc -g -o structit y.tab.c lex.yy.c data_structure.c traduction.c -ll # -Wall -Wextra -Werror
yacc:
	yacc -d structfe.y

lex:
	lex lexer.l

backend:
	lex lexer_be.l && yacc -d structbe.y && gcc -g -o structit_be y.tab.c lex.yy.c -ll

clean :
	@rm -f structit

test : all
	@bash ./test.sh
re : clean all
