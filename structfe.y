%{
        #include "structit.h"
        extern int yylineno;
        extern char *yytext;
        int yylex();
        int yywrap();
        void yyerror(const char *s);
        SymbolTableStack *symbolTableStack = NULL;
        Structure *current_structure = NULL;
%}

%union {
        char *id;
        int val;
        Symbol symbol;
}


%token <val> CONSTANT
%token<id> STRUCT IDENTIFIER
%token SIZEOF
%token PTR_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP
%token EXTERN
%token INT VOID
%token MALLOC
%token IF ELSE WHILE FOR RETURN

%nonassoc ELSE
%start program

%type<symbol> type_specifier declaration_specifiers struct_specifier struct_declaration 
%type<id> direct_declarator declarator
%%

primary_expression
        : IDENTIFIER
        | CONSTANT 
        | '(' expression ')'
        ;

postfix_expression
        : primary_expression
        | postfix_expression '(' ')'
        | postfix_expression '(' argument_expression_list ')'
        | postfix_expression '.' IDENTIFIER
        | postfix_expression PTR_OP IDENTIFIER
        ;

argument_expression_list
        : expression
        | argument_expression_list ',' expression
        ;

unary_expression
        : postfix_expression
        | unary_operator unary_expression
        | SIZEOF unary_expression
        ;

unary_operator
        : '&'
        | '*'
        | '-'
        ;

multiplicative_expression
        : unary_expression
        | multiplicative_expression '*' unary_expression
        | multiplicative_expression '/' unary_expression
        ;

additive_expression
        : multiplicative_expression
        | additive_expression '+' multiplicative_expression
        | additive_expression '-' multiplicative_expression
        ;

relational_expression
        : additive_expression
        | relational_expression '<' additive_expression
        | relational_expression '>' additive_expression
        | relational_expression LE_OP additive_expression
        | relational_expression GE_OP additive_expression
        ;

equality_expression
        : relational_expression
        | equality_expression EQ_OP relational_expression
        | equality_expression NE_OP relational_expression
        ;

logical_and_expression
        : equality_expression
        | logical_and_expression AND_OP equality_expression
        ;

logical_or_expression
        : logical_and_expression
        | logical_or_expression OR_OP logical_and_expression
        ;

expression
        : logical_or_expression
        | unary_expression '=' expression { }
        ;

declaration
        : declaration_specifiers declarator ';' {
                int dataType = $1.dataType;
                char *name = $2;
                int type = $1.type;
                Symbol *content = createSymbol(name, dataType, type, NULL, NULL);
                addSymbol(content, symbolTableStack);
        }
        | struct_specifier ';' { 
                int dataType = $1.dataType;
                int type = $1.type;
                char *name = $1.name;
                Structure *structure = current_structure;
                Symbol *content = createSymbol(name, dataType, type, NULL, structure);
                addSymbol(content, symbolTableStack);
                current_structure = NULL;
                }
        ;

declaration_specifiers
        : EXTERN type_specifier { $$.type = 1; $$.dataType = $2.dataType;}
        | type_specifier { $$ = $1;}
        ;

type_specifier
        : VOID { $$.dataType = 0;}
        | INT { $$.dataType = 1;}
        | struct_specifier { $$.dataType = 2;}
        ;

struct_specifier
        : STRUCT IDENTIFIER '{' struct_declaration_list '}' { $$.name = $2; $$.dataType = 2;}
        | STRUCT IDENTIFIER { $$.name = $2; $$.dataType = 2;}
        ;

struct_declaration_list
        : struct_declaration 
        | struct_declaration_list struct_declaration
        ;

struct_declaration
        : type_specifier declarator ';' {
                if (current_structure == NULL)
                {
                        current_structure = malloc(sizeof(Structure));
                        current_structure->all_fields = malloc(sizeof(Symbol));
                }
                Symbol *tmp = current_structure->all_fields;
                while (tmp->next != NULL)
                        tmp = tmp->next;
                tmp->next = createSymbol($2, $1.dataType, $1.type, NULL, NULL);
                }
        ;

declarator
        : '*' direct_declarator { $$ = $2;}
        | direct_declarator { $$ = $1;}
        ;

direct_declarator
        : IDENTIFIER { $$ = $1;}
        {
                printf("Symbol : %s\n", $1);
        }
        | '(' declarator ')' { $$ = $2;}
        | direct_declarator '(' parameter_list ')' 
        | direct_declarator '(' ')' { $$ = $1;}
        ;

parameter_list
        : parameter_declaration
        | parameter_list ',' parameter_declaration
        ;

parameter_declaration
        : declaration_specifiers declarator
        ;

statement
        : compound_statement
        | expression_statement
        | selection_statement
        | iteration_statement
        | jump_statement 
        ;

compound_statement
        : '{' '}'
        | '{' statement_list '}'
        | '{' declaration_list '}'
        | '{' declaration_list statement_list '}'
        ;

declaration_list
        : declaration
        | declaration_list declaration
        ;

statement_list
        : statement
        | statement_list statement
        ;

expression_statement
        : ';'
        | expression ';'
        ;

selection_statement
        : IF '(' expression ')' statement %prec ELSE
        | IF '(' expression ')' statement else_statement
        ;

else_statement
        : ELSE statement
        ; 

iteration_statement
        : WHILE '(' expression ')' statement
        | FOR '(' expression_statement expression_statement expression ')' statement
        ;

jump_statement
        : RETURN ';'
        | RETURN expression ';'
        ;

program
        : external_declaration
        | program external_declaration
        ;

external_declaration
        : function_definition
        | declaration
        ;

function_definition
        : declaration_specifiers declarator compound_statement 
        ;

%%

void yyerror(const char *s)
{
	fprintf(stderr, "Error compiler at line %d : %s\n", yylineno, s);
}

extern FILE *yyin;

void exit_compiler()
{
        fclose(yyin);
        /* freeSymbolTable(symbolTable); */
        /* freeStackExpression(stackExpression); */
        exit(1);
}

int main(int ac, char **av)
{
        if (ac != 2)
        {
                printf("Usage: %s <filename>\n", av[0]);
                return 1;
        }
        yyin = fopen(av[1], "r");
        if (yyin == NULL)
        {
                printf("Cannot open file %s\n", av[1]);
                return 1;
        }
        symbolTableStack = malloc(sizeof(SymbolTableStack));
        symbolTableStack->top = malloc(sizeof(SymbolTable));
        yyparse();
        free(current_structure);
        fclose(yyin);
        return (0);
}