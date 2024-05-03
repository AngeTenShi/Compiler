%{
        #include "structit.h"
        extern int yylineno;
        extern char *yytext;
        int yylex();
        int yywrap();
        void yyerror(const char *s);
        SymbolTableStack *symbolTableStack = NULL;
        t_typelist *type_list = NULL;
        Structure *current_structure = NULL;
        Symbol *current_functions_parameter = NULL;
        int calcul_result = 0;
        t_type *current_type = NULL;
        t_type *current_type_parameter = NULL;
        char *output_file = NULL;
        t_function *current_function = NULL;
        t_lines *lines = NULL;
        t_expression *current_expressions = NULL;
        t_expression *if_expression = NULL;
        t_expression *else_expression = NULL;
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

%type<symbol> type_specifier declaration_specifiers struct_specifier struct_declaration parameter_declaration parameter_list primary_expression unary_expression postfix_expression expression unary_operator declarator multiplicative_expression additive_expression relational_expression equality_expression logical_and_expression logical_or_expression direct_declarator argument_expression_list declaration expression_statement

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
                $$.code = $1;
        }
        | CONSTANT 
        { 
                $$.name = NULL; 
                int *value = malloc(sizeof(int)); // we need to use this local variable to store the value of the constant during the parsing
                *value = $1;
                $$.value = value;
                $$.code = itoa($1);
        }
        | '(' expression ')' { $$ = $2; $$.code = ft_strcat(strdup("("), strdup($2.code)); $$.code = ft_strcat(strdup($$.code),strdup(")"));}
        ;

postfix_expression
        : primary_expression { $$ = $1; }
        | postfix_expression '(' ')' { $$.code = ft_strcat(strdup($1.code), strdup("()")); }
        | postfix_expression '(' argument_expression_list ')' 
        {
        }
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
                if ((strncmp(tmp->data_type->name, "int", strlen("int")) == 0 && strlen(tmp->data_type->name) == 3) || (strncmp(tmp->data_type->name, "void", strlen("void")) == 0 && strlen(tmp->data_type->name) == 4)) {
                        yyerror("Variable is not a struct\n");
                        exit_compiler();
                }
                if (struct_has_member(tmp->data_type->symbols, $3) == 0) {
                    yyerror("Struct does not have this member\n");
                    exit_compiler();
                }
                Symbol *tmp2 = tmp->data_type->symbols;
                while (tmp2 != NULL)
                {
                        if (strncmp(tmp2->name, $3, strlen($3)) == 0)
                        {
                                $$.value = tmp2;
                                break;
                        }
                        tmp2 = tmp2->next;
                }
        }
        ;

argument_expression_list
        : expression 
        {
                if ($1.name != NULL)
                {
                        Symbol *tmp = get_symbol($1.name, symbolTableStack);
                        if (tmp == NULL)
                        {
                                yyerror("Variable does not exist\n");
                                exit_compiler();
                        }
                        if (tmp->data_type == NULL)
                        {
                                yyerror("Variable is not typed\n");
                                exit_compiler();
                        }
                        if (strncmp(tmp->data_type->name, "int", strlen("int")) != 0 || strlen(tmp->data_type->name) != 3)
                        {
                                if ($1.is_pointer == 0 && tmp->is_pointer == 0)
                                {
                                        yyerror("Argument is not valid\n");
                                        exit_compiler();
                                }
                        }
                        if (tmp->type == 1)
                        {
                                yyerror("Function as argument not allowed\n");
                                exit_compiler();
                        }
                        $$.value = tmp;
                }
                else
                {
                        int *v = $1.value;
                        $$.value = v;
                }
                $$.code = strdup($1.code);
                
        }
        | argument_expression_list ',' expression 
        {
                if ($3.name != NULL)
                {
                        Symbol *tmp = get_symbol($3.name, symbolTableStack);
                        if (tmp == NULL)
                        {
                                yyerror("Variable does not exist\n");
                                exit_compiler();
                        }
                        if (tmp->data_type == NULL)
                        {
                                yyerror("Variable is not typed\n");
                                exit_compiler();
                        }
                        if (strncmp(tmp->data_type->name, "int", strlen("int")) != 0 || strlen(tmp->data_type->name) != 3)
                        {
                                if ($1.is_pointer == 0 && tmp->is_pointer == 0)
                                {
                                        yyerror("Argument is not valid\n");
                                        exit_compiler();
                                }
                        }
                        if (tmp->type == 1)
                        {
                                yyerror("Function as argument not allowed\n");
                                exit_compiler();
                        }
                        $$.value = tmp;
                }
                else
                {
                        int *v = $3.value;
                        $$.value = v;
                }
                $$.code = ft_strcat(strdup($$.code), strdup(","));
                $$.code = ft_strcat(strdup($$.code), strdup($3.code));
        }
        ;

unary_expression
        : postfix_expression { $$ = $1; }
        | unary_operator unary_expression 
        { 
                int *is_neg = $1.value;
                if (is_neg != NULL)
                {
                        if ($2.name != NULL)
                        {
                                Symbol *tmp = get_symbol($2.name, symbolTableStack);
                                if (*is_neg == -1)
                                {
                                        int *v = tmp->value;
                                        *v = *v * -1;
                                        free(is_neg);
                                }
                        }
                        else
                        {
                                int *v = $2.value;
                                *v = *v * -1;
                                free(is_neg);
                        }
                }
                $$ = $2;
                $$.is_pointer = $1.is_pointer;
                if ($1.is_pointer == 1)
                {
                        Symbol *tmp = get_symbol($2.name, symbolTableStack);
                        printf("Dereferencing %s \n", tmp->name);
                        if (tmp->is_pointer != 1)
                        {
                                yyerror("Cannot dereference a non-pointer\n");
                                exit_compiler();
                        }
                        else
                        {
                                int *v = tmp->value;
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
                                if (tmp->data_type == NULL)
                                {
                                        yyerror("Cannot take the address of a non-typed variable\n");
                                        exit_compiler();
                                }
                                else
                                        $$.value = &tmp;
                        }
                }
        }
        | SIZEOF unary_expression { $$ = $2; int *v = malloc(sizeof(int)); *v = sizeof($2); $$.value = v; $$.is_pointer = 3; $$.code = itoa(sizeof($2));}
        ;

unary_operator
        : '&' { $$.is_pointer = 2; $$.code = strdup("&");}
        | '*' { $$.is_pointer = 1; $$.code = strdup("*");}
        | '-' { $$.is_pointer = 0;  int *v = malloc(sizeof(int)); *v = -1; $$.value = v; $$.code = strdup("-");}
        ;

multiplicative_expression
        : unary_expression { $$ = $1;}
        | multiplicative_expression '*' unary_expression 
        {
                Symbol *first;
                Symbol *second;
                int first_member;
                int second_member;
                if ($1.value == NULL)
                {
                        first = get_symbol($1.name, symbolTableStack);
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
                       second = get_symbol($3.name, symbolTableStack);
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
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                char *first_name = (first->name == NULL) ? itoa(first_member) : first->name;
                char *second_name = (second->name == NULL) ? itoa(second_member) : second->name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s * %s", first_name, second_name);
                else
                        sprintf(code, " * %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                // printf("Calcul : %d / %d = %d\n", first_member, second_member, calcul_result);
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                char *first_name = ($1.name == NULL) ? itoa(first_member) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(second_member) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s / %s", first_name, second_name);
                else
                        sprintf(code, " / %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
        }
        ;

additive_expression
        : multiplicative_expression { $$ = $1;}
        | additive_expression '+' multiplicative_expression
        {
                int first_member;
                int second_member;
                char *first_name;
                char *second_name;
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
                        first_name = first->name;
                }
                else
                {
                        first_member = *((int *)$1.value);
                        first_name = itoa(first_member);
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
                        second_name = second->name;
                        second_member = *v;
                }
                else
                {
                        second_member = *((int *)$3.value);
                        second_name = itoa(second_member);
                }
                calcul_result += first_member + second_member;
                int *v = malloc(sizeof(int));
                *v = calcul_result;
                $$.value = v;
                // printf("Calcul : %d + %d = %d\n", first_member, second_member, calcul_result);
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s + %s", first_name, second_name);
                else
                        sprintf(code, " + %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                // printf("Calcul : %d - %d = %d\n", first_member, second_member, calcul_result);
                char    *first_name = ($1.name == NULL) ? itoa(first_member) : $1.name;
                char    *second_name = ($3.name == NULL) ? itoa(second_member) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s - %s", first_name, second_name);
                else
                        sprintf(code, " - %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (first && second)
                {
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
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
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
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s < %s", first_name, second_name);
                else
                        sprintf(code, " < %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (first && second)
                {
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
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
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
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s > %s", first_name, second_name);
                else
                        sprintf(code, " > %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
               if (first && second)
                {
                        if (first->value == NULL || second->value == NULL)
                        {
                                // we don't know at compile time the value of the variable but type is int so we can compare
                                int *v = malloc(sizeof(int));
                                *v = -1;
                                $$.value = v;
                        }
                        else
                        {
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
                        }
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
                {
                        if (first_member == NULL || second_member == NULL)
                        {
                                // we don't know at compile time the value of the variable but type is int so we can compare
                                int *v = malloc(sizeof(int));
                                *v = -1;
                                $$.value = v;
                        }

                        else
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
                }
                else
                {
                        yyerror("Comparison is only allowed on integers or on pointers\n");
                        exit_compiler();
                }
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s <= %s", first_name, second_name);
                else
                        sprintf(code, " <= %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (first && second)
                {
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
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
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
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s >= %s", first_name, second_name);
                else
                        sprintf(code, " >= %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (first && second)
                {
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
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
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
                else if (first->is_pointer && strncmp(second_type, "int", strlen("int")) == 0 && strlen(second_type) == 3 && *((int *)second_member) == 0)
                {
                        if (first->value == NULL)
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
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s == %s", first_name, second_name);
                else
                        sprintf(code, " == %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (first && second)
                {
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
                }
                if (strncmp(first_type, "int", strlen("int")) == 0 && strlen(first_type) == 3)
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
                else if (first->is_pointer && strncmp(second_type, "int", strlen("int")) == 0 && strlen(second_type) == 3 && *((int *)second_member) == 0)
                {
                        if (first->value == NULL)
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
                char *first_name = ($1.name == NULL) ? itoa(*((int *)first_member)) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(*((int *)second_member)) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s != %s", first_name, second_name);
                else
                        sprintf(code, " != %s", second_name);
                $$.code = ft_strcat(strdup($$.code), code);
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
                char *first_name = ($1.name == NULL) ? itoa(first_member) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(second_member) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s && ", first_name);
                else
                {
                        if ($3.code == NULL)
                                sprintf(code, " && %s", second_name);
                        else
                                sprintf(code, " && %s", $3.code);
                }
                $$.code = ft_strcat(strdup($$.code), code);
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
                char *first_name = ($1.name == NULL) ? itoa(first_member) : $1.name;
                char *second_name = ($3.name == NULL) ? itoa(second_member) : $3.name;
                if ($1.value != NULL)
                        free($1.value);
                if ($3.value != NULL)
                        free($3.value);
                char *code = malloc(strlen(first_name) + strlen(second_name) + 10);
                if ($$.code == NULL)
                        sprintf(code, "%s || %s", first_name, second_name);
                else
                {
                        if ($3.code == NULL)
                                sprintf(code, " || %s", second_name);
                        else
                                sprintf(code, " || %s", $3.code);
                }
                $$.code = ft_strcat(strdup($$.code), code);
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
                if (is_struct(symbol))
                {       
                        symbol = (Symbol *)$1.value;
                        if (symbol == NULL)
                                symbol = get_symbol($1.name, symbolTableStack);
                }
                if (symbol == NULL) {
                    yyerror("Variable does not exist\n");
                    exit_compiler();
                }
                if ($3.name != NULL)
                {
                        Symbol *tmp;
                        tmp = get_symbol($3.name, symbolTableStack);
                        if (is_struct(tmp))
                        {
                                tmp = (Symbol *)$3.value;
                        }
                        if (tmp == NULL)
                        {
                                tmp = get_symbol($3.name, symbolTableStack);
                        }
                        if (symbol->data_type == NULL || tmp->data_type == NULL)
                        {
                                yyerror("Cannot assign to a non-typed variable\n");
                                exit_compiler();
                        }
                        if (symbol->data_type == tmp->data_type) // if the type are equal the to assign will be an int with value one
                        {
                                int *v = malloc(sizeof(int));
                                *v = 1;
                                symbol->value = v;
                        }
                        else
                        {
                                // if it's not same datatype we check if it's void * type and give warning but accept malloc to alloc
                                if (strncmp(tmp->data_type->name, "void", strlen("void")) == 0 && strlen(tmp->data_type->name) == 4) 
                                        // printf("Warning : Assigning %s to a void * type\n", symbol->name);
                                if (strncmp(tmp->name, "malloc", strlen("malloc")) != 0)
                                {   
                                        printf("Type of %s is %s\n", tmp->name, tmp->data_type->name);
                                        yyerror("Cannot assign different types\n");
                                        exit_compiler();
                                }
                        }

                }
                else
                {       
                        if ($3.value == NULL)
                        {
                                yyerror("No constant to assign\n");
                                exit_compiler();
                        }
                        int *v = $3.value;
                        int *to_assign = malloc(sizeof(int));
                        *to_assign = *v;
                        // printf("Assigning %d to %s\n", *to_assign, $1.name);
                        symbol->value = to_assign; // the main issue is that i try to assign a value of a function that is not called yet
                }
                char *code = ft_strcat(strdup($1.name), strdup(" = "));
                if ($3.code != NULL)
                        code = ft_strcat(code, strdup($3.code));
                else
                        code = ft_strcat(code, itoa(*((int *)$3.value)));
                $$.code = code;
            }
        ;

declaration
        : declaration_specifiers declarator ';' {
                Symbol *tmp = get_symbol($2.name, symbolTableStack);
                t_type *data_type = $1.data_type;
                char *name = $2.name;
                int type = $1.type;
                int to_push = $1.to_push;
                int is_pointer = $2.is_pointer;
                if (tmp != NULL && (to_push == 1) && (type == 1))
                {
                        yyerror("Variable already declared\n");
                        exit_compiler();
                }
                else if (tmp != NULL && (to_push == 1) && (type == 2))
                {
                        yyerror("Type already declared\n");
                        exit_compiler();
                }
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                Symbol *content = create_symbol(name, data_type, type, default_value, to_push, is_pointer);
                add_symbol(content, &symbolTableStack);
                if (current_functions_parameter != NULL) // case for external definition we don't want to push the parameters so we free it
                {
                        add_arguments_to_function(current_functions_parameter, &current_function);
                        write_function(current_function, output_file);
                        Symbol *tmp = current_functions_parameter;
                        while (tmp != NULL)
                        {
                                Symbol *tmp2 = tmp;
                                tmp = tmp->next;
                                free(tmp2);
                        }
                        current_functions_parameter = NULL;
                        reset_function(&current_function);
                        current_function->pushed = 1;
                }
                char *code = malloc(strlen(data_type->name) + strlen(name) + 10);
                sprintf(code, "%s %s;", data_type->name, name);
                $$.code = code;
        }
        | struct_specifier ';' { 
                t_type *data_type = $1.data_type;
                char *name = $1.name;
                Structure *structure = current_structure;
                int is_pointer = $1.is_pointer;
                if (get_symbol(name, symbolTableStack) != NULL)
                {
                        yyerror("Variable already declared\n");
                        exit_compiler();
                }
                data_type->symbols = structure->all_fields;
                Symbol *tmp = structure->all_fields;
                while (tmp != NULL)
                {
                        if (tmp->data_type == NULL)
                                tmp->data_type = data_type;
                        tmp = tmp->next;
                }
                add_type_to_list(type_list, data_type);
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                Symbol *content = create_symbol(name, data_type, 2, default_value, 1, is_pointer);
                add_symbol(content, &symbolTableStack);
                current_structure = NULL;
                char *code = malloc(strlen(data_type->name) + strlen(name) + 10);
                sprintf(code, "%s %s;", data_type->name, name);
                $$.code = code;
        }
        ;

declaration_specifiers
        : EXTERN type_specifier { $$.type = 1; $$.data_type = $2.data_type; $$.to_push = 0; current_function->is_extern = 1; current_function->return_type = $2.data_type; }
        | type_specifier 
        { 
                $$ = $1;
                if ($$.data_type == NULL)
                {
                        yyerror("Unknown type\n");
                        exit_compiler();
                }
        }
        ;

type_specifier
        : VOID { $$.data_type = get_type("void", type_list); $$.to_push = 1; if (current_type != NULL) current_type_parameter = $$.data_type; else current_type = $$.data_type; }
        | INT { $$.data_type = get_type("int", type_list); $$.to_push = 1; if (current_type != NULL) current_type_parameter = $$.data_type; else current_type = $$.data_type; }
        | struct_specifier 
        { 
                $$.to_push = 1; $$.data_type = $1.data_type;
                if (current_type != NULL)
                        current_type_parameter = $1.data_type;
                else
                        current_type = $1.data_type;
        }
        ;

struct_specifier
        : STRUCT IDENTIFIER '{' struct_declaration_list '}' { $$.name = $2; $$.data_type = create_type($2, current_structure->all_fields);}
        | STRUCT IDENTIFIER { $$.name = $2; $$.data_type = get_type($2, type_list);}
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
                        int *default_value = malloc(sizeof(int));
                        *default_value = 0;
                        current_structure->all_fields = create_symbol($2.name, $1.data_type, $1.type, default_value, 1, $1.is_pointer);
                        current_structure->all_fields->next = NULL;
                        
                }
                else
                {
                        Symbol *tmp = current_structure->all_fields;
                        int *default_value = malloc(sizeof(int));
                        *default_value = 0;
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($2.name, $1.data_type, $1.type, default_value, 1, $1.is_pointer);
                        tmp->next->next = NULL;
                }
        }
        ;

declarator
        : '*' direct_declarator { $$.name = $2.name; $$.is_pointer = 1; if (current_function->pushed == 0) current_function->is_pointer = 1; }
        | direct_declarator { $$.name = $1.name;}
        ;

direct_declarator
        : IDENTIFIER { $$.name = $1; }
        | '(' declarator ')' { $$.name = $2.name; $$.is_pointer = $2.is_pointer; }
        | direct_declarator '(' parameter_list ')'
        {
                if (current_type_parameter != NULL && current_type != NULL)
                {
                        yyerror("Functions pointer not allowed in functions parameter\n");
                        exit_compiler();
                }
                $$.type = 1;
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                Symbol *tmp = create_symbol($1.name, current_type, 1, default_value, 1, $1.is_pointer);
                add_symbol(tmp, &symbolTableStack);
                current_function->name = $1.name;
                current_function->return_type = current_type;
        }     
        | direct_declarator '(' ')'
        {
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                Symbol *tmp = create_symbol($1.name, current_type, 1, default_value, 1, $1.is_pointer);
                add_symbol(tmp, &symbolTableStack);
                current_function->name = $1.name;
                current_function->return_type = current_type;
                current_type = NULL;
        }
        ;

parameter_list
        : parameter_declaration 
        {
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                if ($$.data_type == NULL)
                {
                        yyerror("Unknown type for parameter\n");
                        exit_compiler();
                }
                if (current_functions_parameter == NULL)
                        current_functions_parameter = create_symbol($$.name, $$.data_type, $$.type, default_value, 1, $$.is_pointer);
                else
                {
                        Symbol *tmp = current_functions_parameter;
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($$.name, $$.data_type, $$.type, default_value, 1, $$.is_pointer);;
                }
                current_type_parameter = NULL;
        }
        | parameter_list ',' parameter_declaration
        {
                Symbol *tmp = current_functions_parameter;
                int *default_value = malloc(sizeof(int));
                *default_value = 0;
                if (tmp == NULL)
                        current_functions_parameter = create_symbol($3.name, $3.data_type, $3.type, default_value, 1, $3.is_pointer);
                else
                {
                        while (tmp->next != NULL)
                                tmp = tmp->next;
                        tmp->next = create_symbol($3.name, $3.data_type, $3.type, default_value, 1, $3.is_pointer);
                }
                current_type_parameter = NULL;
        }
        ;

parameter_declaration
        : declaration_specifiers declarator { $$.name = $2.name; $$.data_type = $1.data_type; $$.type = $1.type; $$.to_push = $1.to_push; $$.is_pointer = $2.is_pointer; } 
        ;

statement
        : compound_statement
        | expression_statement { add_expression(&current_expressions, $1.code); }
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
                        add_arguments_to_function(current_functions_parameter, &current_function);
                        current_functions_parameter = NULL;
                }
             }

sortie: 
        '}' 
        { 
                pop_symbol_table(&symbolTableStack); 
        }

compound_statement
        : entree sortie 
        | entree statement_list sortie
        | entree declaration_list sortie
        | entree declaration_list statement_list sortie
        ;


declaration_list
        : declaration { add_line(&lines, $1.code); }
        | declaration_list declaration { add_line(&lines, $2.code); }
        ;

statement_list
        : statement
        | statement_list statement 
        | statement_list declaration
        ;

expression_statement
        : ';' { $$.code = ft_strcat(strdup($$.code), strdup(";")); }
        | expression ';' { $1.code = ft_strcat(strdup($1.code), strdup(";")); $$.code = $1.code; }
        ;

selection_statement
        : IF '(' expression ')' statement %prec THEN { make_if(&lines, $3.code, current_expressions); reset_expressions(&current_expressions); }
        | IF '(' expression ')' statement else_statement { make_if_else(&lines, $3.code, if_expression, else_expression); reset_expressions(&current_expressions); }
        ;

is_else:
        ELSE { if_expression = current_expressions; current_expressions = NULL;}

else_statement
        : is_else statement {  else_expression = current_expressions; }
        ;

iteration_statement
        : WHILE '(' expression ')' statement 
        {
                make_while(&lines, $3.code, current_expressions);
                reset_expressions(&current_expressions);
        }
        | FOR '(' expression_statement expression_statement expression ')' statement
        {
                $3.code[strlen($3.code) - 1] = '\0';
                $4.code[strlen($4.code) - 1] = '\0';
                make_for(&lines, $3.code, $4.code, $5.code, current_expressions);
                reset_expressions(&current_expressions);
        }
        ;

jump_statement
        : RETURN ';' { add_expression(&current_expressions, strdup("return ;")); }
        | RETURN expression ';' { char *code = ft_strcat(strdup("return "), ft_strcat(strdup($2.code), strdup(";"))); add_expression(&current_expressions, code); }
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
        { 
                write_function(current_function, output_file); 
                reset_function(&current_function); 
                if (current_expressions != NULL) 
                { 
                        t_expression *tmp = current_expressions;
                        while (tmp != NULL)
                        {
                                add_line(&lines, tmp->expression_line);
                                tmp = tmp->next;
                        }                        
                } 
                add_line(&lines, strdup("}\n")); 
                write_statement(lines, output_file); 
                reset_lines(&lines); 
        }
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
        exit(1);
}

int main(int ac, char **av)
{
        if (ac < 2 || ac > 4)
        {
                printf("Usage: %s <filename>\n", av[0]);
                printf("Usage: %s <filename> -o output\n", av[0]);
                return 1;
        }
        if (strncmp(av[1] + strlen(av[1]) - 2, ".c", 2) != 0)
        {
                printf("File must be a .c file\n");
                return 1;
        }
        if (ac == 4 && strcmp(av[2], "-o") == 0)
        {
                if (ac < 4)
                {
                        printf("Missing output file name\n");
                        return 1;
                }
                output_file = av[3];
        }
        else
        {
                output_file = "a.out";
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
        current_function = malloc(sizeof(t_function));
        reset_function(&current_function);
        yyparse();
        free(current_structure);
        free(symbolTableStack);
        free(type_list);
        fclose(yyin);
        return (0);
}