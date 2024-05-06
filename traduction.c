#include "structit.h"

void add_arguments_to_function(Symbol *arguments, t_function **function)
{
    if (function == NULL)
        return ;
    if (*function == NULL)
        return ;
    (*function)->arguments = arguments;
}


void    write_function(t_function *function, char *filename)
{
    FILE *file = fopen(filename, "a+");
    if (file == NULL)
    {
        printf("Error opening file!\n");
        exit(1);
    }

    fseek(file, 0, SEEK_END); // Move the file pointer to the end of the file
    if (function->is_extern == 1)
    {
        fprintf(file, "extern ");
    }
    char *data_type_output = (strncmp(function->return_type->name, "int", 3) == 0) ? "int" : "void";
    fprintf(file, "%s", data_type_output);
    if (function->is_pointer == 1 && (strncmp(data_type_output, "void", 4) == 0 && strlen(data_type_output) == 4))
        fprintf(file, "*");
    fprintf(file, " %s(", function->name);
    Symbol *arguments = function->arguments;
    while (arguments != NULL)
    {
        char *data_type_arg = (strncmp(arguments->data_type->name, "int", 3) == 0) ? "int" : "void *";
        fprintf(file, "%s %s", data_type_arg, arguments->name);
        if (arguments->next != NULL)
            fprintf(file, ", ");
        arguments = arguments->next;
    }
    fprintf(file, ")");
    if (function->is_extern == 1)
        fprintf(file, ";\n");
    else
    {
        fprintf(file, "\n");
        fprintf(file, "{\n");
        // for all structures create void * or int for each field at beggining of function
        Symbol *fields = function->arguments;
        char *tab = strdup("");
        for (int i = 0; i < tab_level + 1; i++) {
            tab = ft_strcat(tab, strdup("\t"));
        }
        while (fields != NULL)
        {
            if (is_struct(fields))
            {
                Symbol *tmp = fields->data_type->symbols;
                while (tmp != NULL)
                {
                    char *data_type_output = (strncmp(tmp->data_type->name, "int", 3) == 0) ? "int" : "void *";
                    char *name = malloc(strlen(tab) + strlen(data_type_output) + 1 + strlen(fields->name) + strlen(fields->data_type->name) + strlen(tmp->name) + 3);
                    sprintf(name, "%s%s %s_%s_%s;",tab, data_type_output, fields->name, fields->data_type->name, tmp->name);
                    fprintf(file, "%s\n", name);
                    tmp = tmp->next;
                }
            }
            fields = fields->next;
        }
    }
    fclose(file);
}

void    reset_lines(t_lines **lines)
{
    if (lines == NULL)
        return ;
    if (*lines == NULL)
        return ;
    t_lines *tmp = *lines;
    while (tmp != NULL)
    {
        t_lines *next = tmp->next;
        free(tmp->line);
        free(tmp);
        tmp = next;
    }
    *lines = NULL;
}
void    write_statement(t_lines *lines, char *filename)
{
    FILE *file = fopen(filename, "a+");
    if (file == NULL)
    {
        printf("Error opening file!\n");
        exit(1);
    }
    fseek(file, 0, SEEK_END);
    t_lines *tmp = lines;
    while (tmp != NULL)
    {
        fprintf(file, "%s\n", tmp->line);
        tmp = tmp->next;
    }
    fclose(file);
}

void    add_line(t_lines **lines, char *content)
{
    if (lines == NULL)
        return ;
    if (*lines == NULL)
    {
        *lines = malloc(sizeof(t_lines));
        (*lines)->line = content;
        (*lines)->next = NULL;
        return ;
    }
    t_lines *tmp = *lines;
    while (tmp->next != NULL)
    {
        tmp = tmp->next;
    }
    tmp->next = malloc(sizeof(t_lines));
    tmp->next->line = content;
    tmp->next->next = NULL;
}


void    add_expression(t_expression **expressions, char *content)
{
    if (!content)
        return ;
    if (expressions == NULL)
        return ;
    if (*expressions == NULL)
    {
        *expressions = malloc(sizeof(t_expression));
        (*expressions)->expression_line = content;
        (*expressions)->next = NULL;
        return ;
    }
    t_expression *tmp = *expressions;
    while (tmp->next != NULL)
    {
        tmp = tmp->next;
    }
    tmp->next = malloc(sizeof(t_expression));
    tmp->next->expression_line = content;
    tmp->next->next = NULL;
}

void    reset_expressions(t_expression **expressions)
{
    if (expressions == NULL)
        return ;
    if (*expressions == NULL)
        return ;
    *expressions = NULL;
}

void    insert_expression(t_expression **expressions, t_expression *exp)
{
    if (expressions == NULL)
        return ;
    if (exp == NULL)
        return ;
    if (*expressions == NULL)
    {
        *expressions = exp;
        return ;
    }
    t_expression *tmp = *expressions;
    while (tmp->next != NULL)
    {
        tmp = tmp->next;
    }
    tmp->next = exp;

}

char *itoa(int value)
{
   char *result = malloc(12);
    sprintf(result, "%d", value);
    return result;
}

char *ft_strcat(char *src, char *dest)
{
    if (src == NULL && dest == NULL)
        return (NULL);
    if (src == NULL || strlen(src) == 0)
        return (dest);
    if (dest == NULL || strlen(dest) == 0)
        return (src);
    char *result = malloc(strlen(src) + strlen(dest) + 1);
    int i = 0;
    int j = 0;
    while (src[i] != '\0')
    {
        result[i] = src[i];
        i++;
    }
    while (dest[j] != '\0')
    {
        result[i] = dest[j];
        i++;
        j++;
    }
    result[i] = '\0';
    free(src);
    free(dest);
    return (result);
}

char    *create_label()
{
    char *label = malloc(10);
    int i = 0;
    while (i < 9)
    {
        label[i] = (rand() % 26) + 65; // just a random thing
        i++;
    }
    label[i] = '\0';
    return (label);
}

void    print_expression(t_expression *exp)
{
    t_expression *tmp = exp;
    while (tmp != NULL)
    {
        printf("%s\n", tmp->expression_line);
        tmp = tmp->next;
    }

}

t_expression    *make_for(t_lines **lines, char *init, char *condition, char *increment, t_expression *statement)
{
    t_expression *ret = NULL;
    char *stat_label = ft_strcat(strdup("stat_"), create_label());
    char *cond_label = ft_strcat(strdup("cond_"), create_label());
    // a for should be like : for (init; condition; increment) => goto cond_label; cond_label : cond goto stat; stat_label : statement increment;  
    add_expression(&ret, ft_strcat(ft_strcat(strdup("goto "), strdup(cond_label)), strdup(";")));
    add_expression(&ret, strdup(""));
    add_expression(&ret, ft_strcat(cond_label, strdup(":")));
    add_expression(&ret, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(stat_label)), strdup(";")));
    add_expression(&ret, strdup(""));
    add_expression(&ret,ft_strcat(stat_label, strdup(":")));
    t_expression *tmp = statement;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_expression(&ret, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_expression(&ret, strdup(""));
    add_expression(&ret,  increment);
    return (ret);
}

t_expression    *make_while(t_lines **lines, char *condition, t_expression *expression)
{
    t_expression *ret = NULL;
    char *cond_label = ft_strcat(strdup("cond_"), create_label());
    char *stat_label = ft_strcat(strdup("stat_"), create_label());
    add_expression(&ret, ft_strcat(strdup(cond_label), strdup(":")));
    add_expression(&ret, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(stat_label)), strdup(";")));
    add_expression(&ret, ft_strcat(ft_strcat(strdup("goto "), cond_label), strdup(";")));
    add_expression(&ret, strdup(""));
    add_expression(&ret, ft_strcat(stat_label, strdup(":")));
    t_expression *tmp = expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_expression(&ret, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    return (ret);
}

char* reverse_condition(char* condition) {
    char *reversed_condition = malloc(strlen(condition) + 1);
    for (int i = 0; condition[i] != '\0'; i++) {
        switch (condition[i]) {
            case '!':
                if (condition[i+1] == '=') {
                    reversed_condition = ft_strcat(reversed_condition, strdup("=="));
                    i++;
                }
                break;
            case '=':
                if (condition[i+1] == '=') {
                    reversed_condition = ft_strcat(reversed_condition, strdup("!="));
                    i++;
                }
                break;
            case '>':
                if (condition[i+1] == '=') {
                    reversed_condition = ft_strcat(reversed_condition, strdup("<"));
                    i++;
                } else {
                    reversed_condition = ft_strcat(reversed_condition, strdup("<="));
                }
                break;
            case '<':
                if (condition[i+1] == '=') {
                    reversed_condition = ft_strcat(reversed_condition, strdup(">"));
                    i++;
                } else {
                    reversed_condition = ft_strcat(reversed_condition, strdup(">="));
                }
                break;
            case '&':
                if (condition[i+1] == '&') {
                    reversed_condition = ft_strcat(reversed_condition, strdup("||"));
                    i++;
                }
                break;
            case '|':
                if (condition[i+1] == '|') {
                    reversed_condition = ft_strcat(reversed_condition, strdup("&&"));
                    i++;
                }
                break;
            default:
                char *tmp = malloc(2);
                tmp[0] = condition[i];
                tmp[1] = '\0';
                reversed_condition = ft_strcat(reversed_condition, tmp);
                break;
        }
    }
    return (reversed_condition);
}

t_expression    *make_if(t_lines **lines, char *condition, t_expression *expression)
{
    t_expression *ret = NULL;  
    char *label = ft_strcat(strdup("endif_"), create_label());
    add_expression(&ret, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(label)), strdup(";")));
    t_expression *tmp = expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_expression(&ret, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_expression(&ret,ft_strcat(label, strdup(":")));
    return (ret);
}


t_expression    *make_if_else(t_lines **lines, char *condition, t_expression *if_expression, t_expression *else_expression)
{
    // if (reverse_condition) goto else_label; { if_expression } else_label: { else_expression }
    t_expression *ret = NULL;
    char *else_label = ft_strcat(strdup("else_"), create_label());
    add_expression(&ret, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), reverse_condition(condition)), strdup(") goto ")), strdup(else_label)), strdup(";")));
    add_expression(&ret, strdup("{"));
    t_expression *tmp = if_expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_expression(&ret, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_expression(&ret, strdup("}"));
    add_expression(&ret, ft_strcat(strdup(else_label), strdup(":")));
    add_expression(&ret, strdup("{"));
    tmp = else_expression;
    while (tmp != NULL)
    {
        add_expression(&ret, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_expression(&ret,strdup("}"));
}