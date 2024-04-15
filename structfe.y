%{
        #include "structit.h"
        extern int yylineno;
        extern char *yytext;
        int yylex();
        int yywrap();
        void yyerror(const char *s);
        SymbolTableStack *symbolTableStack = NULL;
        TypeList *type_list = NULL;
        Structure *current_structure = NULL;
        Symbol *current_functions_parameter = NULL;
%}

%union {
        char *id;
        int val;
        void *ptr;
        Symbol symbol;
}


%token <val> CONSTANT
%token<id> STRUCT IDENTIFIER
%token SIZEOF
%token PTR_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP
%token EXTERN
%token INT VOID
%token IF ELSE WHILE FOR RETURN

%nonassoc THEN
%nonassoc ELSE

%start program

%type<symbol> type_specifier declaration_specifiers struct_specifier struct_declaration parameter_declaration parameter_list primary_expression unary_expression postfix_expression expression unary_operator declarator
%type<id> direct_declarator  

%%

primary_expression
        : IDENTIFIER 
        {
                Symbol *tmp = get_symbol($1, symbolTableStack);
                if (tmp == NULL) {
                    yyerror("Variable does not exist\n");
                    exit_compiler();
                }
                if (tmp->type == 2) {
                    yyerror("Variable is a struct\n");
                    exit_compiler();
                }
                $$.name = $1;
                $$.value = tmp;
        }
        | CONSTANT { $$.name = NULL; $$.value = &$1; }
        | '(' expression ')' { $$ = $2;}
        ;

postfix_expression
        : primary_expression { $$ = $1; }
        | postfix_expression '(' ')'
        | postfix_expression '(' argument_expression_list ')' 
        | postfix_expression PTR_OP IDENTIFIER 
        {
                Symbol *tmp = get_symbol($1.name, symbolTableStack);
                if (tmp == NULL)
                {
                    yyerror("Variable does not exist\n");
                    exit_compiler();
                }
                if (tmp->data_type == NULL)
                {
                    yyerror("Variable is not a struct\n");
                    exit_compiler();
                }
                if (tmp->data_type->name == "int" || tmp->data_type->name == "void") {
                    yyerror("Variable is not a struct\n");
                    exit_compiler();
                }
                if (struct_has_member(tmp->data_type->symbols, $3) == 0) {
                    yyerror("Struct does not have this member\n");
                    exit_compiler();
                }
        }
        ;

argument_expression_list
        : expression
        | argument_expression_list ',' expression
        ;

unary_expression
        : postfix_expression { $$ = $1; }
        | unary_operator unary_expression { $$ = $2; }
        | SIZEOF unary_expression { $$ = $2; }
        ;

unary_operator
        : '&' { $$.is_pointer = 1;}
        | '*' { $$.is_pointer = 1;}
        | '-' { $$.is_pointer = 0;}
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
        | unary_expression '=' expression {
                Symbol *symbol = get_symbol($1.name, symbolTableStack);
                if (symbol == NULL) {
                    yyerror("Variable does not exist\n");
                    exit_compiler();
                }
                if (symbol->type == 1) {
                    yyerror("Cannot assign a value to a function\n");
                    exit_compiler();
                }
                if (symbol->type == 2) {
                    yyerror("Cannot assign a value to a struct\n");
                    exit_compiler();
                }
                // set_variable_value($1.name, symbolTableStack, $3);
            }
        ;

declaration
        : declaration_specifiers declarator ';' {
                Type *data_type = $1.data_type;
                char *name = $2.name;
                int type = $1.type;
                int to_push = $1.to_push;
                int is_pointer = $2.is_pointer;
                Symbol *content = create_symbol(name, data_type, type, NULL, to_push, is_pointer);
                add_symbol(content, &symbolTableStack);
                if (to_push == 0)
                        pop_symbol_table(&symbolTableStack);
        }
        | struct_specifier ';' { 
                Type *data_type = $1.data_type;
                int type = $1.type;
                char *name = $1.name;
                Structure *structure = current_structure;
                int is_pointer = $1.is_pointer;
                Symbol *content = create_symbol(name, NULL, type, NULL, 1, is_pointer);
                data_type->symbols = structure->all_fields;
                add_type_to_list(type_list, data_type);
                add_symbol(content, &symbolTableStack);
                current_structure = NULL;
                }
        ;

declaration_specifiers
        : EXTERN type_specifier { $$.type = 1; $$.data_type = $2.data_type; $$.to_push = 0; $$.is_pointer = 0;  }
        | type_specifier { $$ = $1; }
        ;

type_specifier
        : VOID { $$.data_type = get_type("void", type_list); $$.to_push = 1; $$.is_pointer = 0; }
        | INT { $$.data_type = get_type("int", type_list); $$.to_push = 1; $$.is_pointer = 0;}
        | struct_specifier { $$.to_push = 1; $$.is_pointer = 0; $$.data_type = $1.data_type; }
        ;

struct_specifier
        : STRUCT IDENTIFIER '{' struct_declaration_list '}' { $$.name = $2; $$.data_type = create_type($2, current_structure->all_fields);}
        | STRUCT IDENTIFIER { $$.name = $2; $$.data_type = create_type($2, NULL); $$.to_push = 1;}
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
                        current_structure->all_fields = create_symbol($2.name, $1.data_type, $1.type, NULL, 1, $1.is_pointer);
                        current_structure->all_fields->next = NULL;
                        
                }
                else
                {
                        Symbol *tmp = current_structure->all_fields;
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($2.name, $1.data_type, $1.type, NULL, 1, $1.is_pointer);
                        }
        }
        ;

declarator
        : '*' direct_declarator { $$.name = $2; $$.is_pointer = 1;}
        | direct_declarator { $$.name = $1; $$.is_pointer = 0; }
        ;

direct_declarator
        : IDENTIFIER { $$ = $1; }
        | '(' declarator ')' { $$ = $2.name;}
        | direct_declarator '(' parameter_list ')'
        {
                $$ = $1;
                SymbolTable *to_push = create_symbol_table();
                Symbol *tmp = create_symbol($1, NULL, 1, NULL, 1, 0);
                add_symbol(tmp, &symbolTableStack);
                printf("Fun push parameter : %s\n", $1);
                push_symbol_table(to_push, &symbolTableStack);
                add_symbol(current_functions_parameter, &symbolTableStack);
                current_functions_parameter = NULL;
        }     
        | direct_declarator '(' ')'
        {
                $$ = $1;
                SymbolTable *to_push = create_symbol_table();
                Symbol *tmp = create_symbol($1, NULL, 1, NULL, 1, 0);
                add_symbol(tmp, &symbolTableStack);
                printf("Fun push : %s\n", $1);
                push_symbol_table(to_push, &symbolTableStack);
        }
        ;

parameter_list
        : parameter_declaration 
        {
                if (current_functions_parameter == NULL)
                        current_functions_parameter = create_symbol($$.name, $$.data_type, $$.type, NULL, 1, $$.is_pointer);
                else
                {
                        Symbol *tmp = current_functions_parameter;
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($$.name, $$.data_type, $$.type, NULL, 1, $$.is_pointer);;
                }
        }
        | parameter_list ',' parameter_declaration
        {
                Symbol *tmp = current_functions_parameter;
                if (tmp == NULL)
                        current_functions_parameter = create_symbol($3.name, $3.data_type, $3.type, NULL, 1, $3.is_pointer);
                else
                {
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($3.name, $3.data_type, $3.type, NULL, 1, $3.is_pointer);
                }
        }
        ;

parameter_declaration
        : declaration_specifiers declarator { $$.name = $2.name; $$.data_type = $1.data_type; $$.type = $1.type; $$.to_push = $1.to_push; $$.is_pointer = $2.is_pointer; } 
        ;

statement
        : compound_statement
        | expression_statement
        | selection_statement { pop_symbol_table(&symbolTableStack);}
        | iteration_statement { pop_symbol_table(&symbolTableStack); }
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
        | statement_list declaration
        ;

expression_statement
        : ';'
        | expression ';'
        ;

selection_statement
        : IF '(' expression ')' statement %prec THEN { SymbolTable *to_push = create_symbol_table(); push_symbol_table(to_push, &symbolTableStack); }
        | IF '(' expression ')' statement ELSE statement { SymbolTable *to_push = create_symbol_table(); push_symbol_table(to_push, &symbolTableStack); }
        ;

iteration_statement
        : WHILE '(' expression ')' statement { SymbolTable *to_push = create_symbol_table(); push_symbol_table(to_push, &symbolTableStack); }
        | FOR '(' expression_statement expression_statement expression ')' statement { SymbolTable *to_push = create_symbol_table(); push_symbol_table(to_push, &symbolTableStack); }
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
        : declaration_specifiers declarator compound_statement { pop_symbol_table(&symbolTableStack); }
        ;

%%

void yyerror(const char *s)
{
	fprintf(stderr, "Error compiler at line %d : %s", yylineno, s);
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
        type_list = create_type_list();
        yyparse();
        print_symbol_table(symbolTableStack->top);
        free(current_structure);
        free(symbolTableStack);
        free(type_list);
        fclose(yyin);
        return (0);
}