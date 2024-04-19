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
        int calcul_result = 0;
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

%type<symbol> type_specifier declaration_specifiers struct_specifier struct_declaration parameter_declaration parameter_list primary_expression unary_expression postfix_expression expression unary_operator declarator multiplicative_expression additive_expression relational_expression equality_expression logical_and_expression logical_or_expression
%type<id> direct_declarator  

%%

primary_expression
        : IDENTIFIER 
        {
                Symbol *tmp = get_symbol($1, symbolTableStack);
                if (tmp == NULL) {
                    yyerror("Symbol does not exist\n");
                    exit_compiler();
                }
                $$.name = $1;
                $$.value = NULL;
        }
        | CONSTANT 
        { 
                $$.name = NULL; 
                int *value = malloc(sizeof(int)); // we need to use this local variable to store the value of the constant during the parsing
                *value = $1;
                $$.value = value;
        }
        | '(' expression ')' { $$ = $2; calcul_result = 0;}
        ;

postfix_expression
        : primary_expression { $$ = $1; }
        | postfix_expression '(' ')'
        | postfix_expression '(' argument_expression_list ')' 
        | postfix_expression PTR_OP IDENTIFIER 
        {
                print_symbol_table(symbolTableStack->top);
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
                if ((strncmp(tmp->data_type->name, "int", strlen("int")) == 0 && strlen(tmp->data_type->name) == 3) || (strncmp(tmp->data_type->name, "void", strlen("void")) == 0 && strlen(tmp->data_type->name) == 4)) {
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
        | unary_operator unary_expression 
        { 
                int *is_neg = $1.value;
                if (*is_neg == -1)
                {
                        int *v = $2.value;
                        *v = *v * -1;
                        free(is_neg);
                }
                $$ = $2;
                if ($1.is_pointer == 1)
                {
                        if ($2.is_pointer != 1)
                        {
                                yyerror("Cannot dereference a non-pointer\n");
                                exit_compiler();
                        }
                        else
                        {
                                int *v = $2.value;
                                $$.value = v;
                        }
                }
                else if ($1.is_pointer == 2)
                {
                        if ($2.is_pointer != 0)
                        {
                                yyerror("Cannot take the address of a pointer\n");
                                exit_compiler();
                        }
                        else
                        {
                                Symbol *tmp = get_symbol($2.name, symbolTableStack);
                                $$.value = &(tmp->value);
                        }
                }
        }
        | SIZEOF unary_expression { $$ = $2; int *v = malloc(sizeof(int)); *v = sizeof($2); $$.value = v;}
        ;

unary_operator
        : '&' { $$.is_pointer = 2;}
        | '*' { $$.is_pointer = 1;}
        | '-' { $$.is_pointer = 0;  int *v = malloc(sizeof(int)); *v = -1; $$.value = v;}
        ;

multiplicative_expression
        : unary_expression { $$ = $1;}
        | multiplicative_expression '*' unary_expression 
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Multiplication is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Multiplication is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);        
                calcul_result += first_member * second_member;
                printf("Calcul : %d * %d = %d\n", first_member, second_member, calcul_result);
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | multiplicative_expression '/' unary_expression
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Division is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Division is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);
                if (second_member == 0)
                {
                        yyerror("Division by zero\n");
                        exit_compiler();
                }
                calcul_result += first_member / second_member;
                printf("Calcul : %d / %d = %d\n", first_member, second_member, calcul_result);
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

additive_expression
        : multiplicative_expression { $$ = $1;}
        | additive_expression '+' multiplicative_expression
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Addition is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Addition is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);
                calcul_result += first_member + second_member;
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                printf("Calcul : %d + %d = %d\n", first_member, second_member, calcul_result);
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | additive_expression '-' multiplicative_expression
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Substraction is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Substraction is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);
                calcul_result += first_member - second_member;
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                printf("Calcul : %d - %d = %d\n", first_member, second_member, calcul_result);
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

relational_expression
        : additive_expression { $$ = $1;}
        | relational_expression '<' additive_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value < second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f < s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | relational_expression '>' additive_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value > second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f > s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | relational_expression LE_OP additive_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value <= second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f <= s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | relational_expression GE_OP additive_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value >= second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f >= s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

equality_expression
        : relational_expression { $$ = $1;}
        | equality_expression EQ_OP relational_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value == second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f == s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        | equality_expression NE_OP relational_expression
        {
                char *first_type;
                char *second_type;
                Symbol *first = NULL;
                Symbol *second = NULL;
                void *first_member;
                void *second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
                        first_type = first->data_type->name;
                        first_member = first->value;
                }
                else
                {
                        first_member = $1.value;
                        first_type = "int";
                }
                if ($3.value == NULL)
                {
                        second = get_symbol($3.name, symbolTableStack);
                        second_type = second->data_type->name;
                        second_member = second->value;
                }
                else 
                {
                        second_member = $3.value;
                        second_type = "int";
                }
                if (first_type == NULL || second_type == NULL)
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if ((strncmp(first_type, second_type, strlen(first_type)) != 0) && strlen(first_type) != strlen(second_type))
                {
                        yyerror("Comparison is only allowed on same type\n");
                        exit_compiler();
                }
                if (first->is_pointer != second->is_pointer)
                {
                        yyerror("Comparison is not allowed between pointers and not pointers\n");
                        exit_compiler();
                }
                if (first->is_pointer && second->is_pointer)
                {
                        if (first->value != second->value)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        int f = *((int *)first_member);
                        int s = *((int *)second_member);
                        if (f != s)
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                $$.value = v;
                        }
                        else
                        {
                                int *v = malloc(sizeof(int));
                                *v = 0;
                                $$.value = v;
                        }
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

logical_and_expression
        : equality_expression { $$ = $1;}
        | logical_and_expression AND_OP equality_expression
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Logical and is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Logical and is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);
                if (first_member && second_member)
                {
                        int *v = malloc(sizeof(int));
                        *v = 1;
                        $$.value = v;
                }
                else
                {
                        int *v = malloc(sizeof(int));
                        *v = 0;
                        $$.value = v;
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

logical_or_expression
        : logical_and_expression { $$ = $1;}
        | logical_or_expression OR_OP logical_and_expression
        {
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        Symbol *first = get_symbol($1.name, symbolTableStack);
                        if (strncmp(first->data_type->name, "int", strlen("int")) != 0 || strlen(first->data_type->name) != 3) 
                        {
                                yyerror("Logical or is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)first->value;
                        first_member = *v;
                }
                else
                {
                        int *v = (int *)$1.value;
                        first_member = *v;
                }
                if ($3.value == NULL)
                {
                        Symbol *second = get_symbol($3.name, symbolTableStack);
                        if (strncmp(second->data_type->name, "int", strlen("int")) != 0 || strlen(second->data_type->name) != 3) 
                        {
                                yyerror("Logical or is only allowed on integers\n");
                                exit_compiler();
                        }
                        int *v = (int *)second->value;
                        second_member = *v;
                }
                else 
                        second_member = *((int *)$3.value);
                if (first_member || second_member)
                {
                        int *v = malloc(sizeof(int));
                        *v = 1;
                        $$.value = v;
                }
                else
                {
                        int *v = malloc(sizeof(int));
                        *v = 0;
                        $$.value = v;
                }
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
        }
        ;

expression
        : logical_or_expression { $$ = $1;}
        | unary_expression '=' expression 
        {
                if ($1.name == NULL)
                {
                        yyerror("Cannot assign to a constant\n");
                        exit_compiler();
                }
                Symbol *symbol = get_symbol($1.name, symbolTableStack);
                if (symbol == NULL) {
                    yyerror("Variable does not exist\n");
                    exit_compiler();
                }
                int *v = $3.value;
                int *to_assign = malloc(sizeof(int));
                *to_assign = *v;
                printf("Assigning %d to %s\n", *to_assign, $1.name);
                symbol->value = to_assign;
            }
        ;

declaration
        : declaration_specifiers declarator ';' {
                Type *data_type = $1.data_type;
                char *name = $2.name;
                int type = $1.type;
                int to_push = $1.to_push;
                int is_pointer = $2.is_pointer;
                if (get_symbol(name, symbolTableStack) != NULL && (to_push == 1) && (type == 1))
                {
                        yyerror("Variable already declared\n");
                        exit_compiler();
                }
                Symbol *content = create_symbol(name, data_type, type, NULL, to_push, is_pointer);
                add_symbol(content, &symbolTableStack);
                if (current_functions_parameter != NULL) // case for external definition we don't want to push the parameters so we free it
                {
                        Symbol *tmp = current_functions_parameter;
                        while (tmp != NULL)
                        {
                                Symbol *tmp2 = tmp;
                                tmp = tmp->next;
                                free(tmp2);
                        }
                        current_functions_parameter = NULL;
                }

        }
        | struct_specifier ';' { 
                Type *data_type = $1.data_type;
                char *name = $1.name;
                Structure *structure = current_structure;
                int is_pointer = $1.is_pointer;
                if (get_symbol(name, symbolTableStack) != NULL)
                {
                        yyerror("Variable already declared\n");
                        exit_compiler();
                }
                data_type->symbols = structure->all_fields;
                add_type_to_list(type_list, data_type);
                Symbol *content = create_symbol(name, data_type, 2, NULL, 1, is_pointer);
                printf("Adding type to list\n");
                add_symbol(content, &symbolTableStack);
                current_structure = NULL;
                }
        ;

declaration_specifiers
        : EXTERN type_specifier { $$.type = 1; $$.data_type = $2.data_type; $$.to_push = 0; $$.is_pointer = 0; }
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
                Symbol *tmp = create_symbol($1, NULL, 1, NULL, 1, 0);
                add_symbol(tmp, &symbolTableStack);

        }     
        | direct_declarator '(' ')'
        {
                $$ = $1;
                Symbol *tmp = create_symbol($1, NULL, 1, NULL, 1, 0);
                add_symbol(tmp, &symbolTableStack);
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
        | selection_statement 
        | iteration_statement 
        | jump_statement
        ;

entree : 
        '{' {   
                SymbolTable *to_push = create_symbol_table(); 
                push_symbol_table(to_push, &symbolTableStack); 
                if (current_functions_parameter != NULL)
                {
                        add_symbol(current_functions_parameter, &symbolTableStack);
                        current_functions_parameter = NULL;
                }
             }

sortie: 
        '}' { pop_symbol_table(&symbolTableStack); }

compound_statement
        : entree sortie
        | entree statement_list sortie
        | entree declaration_list sortie
        | entree declaration_list statement_list sortie
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
        : IF '(' expression ')' statement %prec THEN
        | IF '(' expression ')' statement ELSE statement
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
        free(current_structure);
        free(symbolTableStack);
        free(type_list);
        fclose(yyin);
        return (0);
}