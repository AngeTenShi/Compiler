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
    if (content == NULL)
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

t_expression    *remove_last_expression(t_expression **expressions)
{
    // remove last expression from the list and return it
    if (expressions == NULL)
        return (NULL);
    if (*expressions == NULL)
        return (NULL);
    t_expression *tmp = *expressions;
    t_expression *prev = NULL;
    while (tmp->next != NULL)
    {
        prev = tmp;
        tmp = tmp->next;
    }
    if (prev == NULL)
    {
        *expressions = NULL;
        return (tmp);
    }
    prev->next = NULL;
    return (tmp);
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

void    convert_to_three_address(t_lines **lines, t_expression *expression)
{
    // TODO
}

void    make_for(t_lines **lines, char *init, char *condition, char *increment, t_expression *statement)
{
    char *stat_label = ft_strcat(strdup("stat_"), create_label());
    char *cond_label = ft_strcat(strdup("cond_"), create_label());
    // a for should be like : for (init; condition; increment) => goto cond_label; cond_label : cond goto stat; stat_label : statement increment;  
    add_line(lines, ft_strcat(ft_strcat(strdup("goto "), strdup(cond_label)), strdup(";")));
    add_line(lines, strdup(""));
    add_line(lines, ft_strcat(cond_label, strdup(":")));
    add_line(lines, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(stat_label)), strdup(";")));
    add_line(lines, strdup(""));
    add_line(lines, ft_strcat(stat_label, strdup(":")));
    t_expression *tmp = statement;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_line(lines, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
}

void    make_while(t_lines **lines, char *condition, t_expression *expression)
{
    char *cond_label = ft_strcat(strdup("cond_"), create_label());
    char *stat_label = ft_strcat(strdup("stat_"), create_label());
    add_line(lines, ft_strcat(strdup(cond_label), strdup(":")));
    add_line(lines, ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(stat_label)));
    add_line(lines, ft_strcat(ft_strcat(strdup("goto "), cond_label), strdup(";")));
    add_line(lines, strdup(""));
    add_line(lines, ft_strcat(stat_label, strdup(":")));
    t_expression *tmp = expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_line(lines, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
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

void    make_if(t_lines **lines, char *condition, t_expression *expression)
{
    // if (condition) goto label; label: expression
    char *label = ft_strcat(strdup("endif_"), create_label());
    add_line(lines, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), condition), strdup(") goto ")), strdup(label)), strdup(";")));
    t_expression *tmp = expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_line(lines, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_line(lines, ft_strcat(label, strdup(":")));
}


void    make_if_else(t_lines **lines, char *condition, t_expression *if_expression, t_expression *else_expression)
{
    // if (reverse_condition) goto else_label; { if_expression } else_label: { else_expression }
    char *else_label = ft_strcat(strdup("else_"), create_label());
    add_line(lines, ft_strcat(ft_strcat(ft_strcat(ft_strcat(strdup("if ("), reverse_condition(condition)), strdup(") goto ")), strdup(else_label)), strdup(";")));
    add_line(lines, strdup("{"));
    t_expression *tmp = if_expression;
    t_expression *prev = NULL;
    while (tmp != NULL)
    {
        add_line(lines, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_line(lines, strdup("}"));
    add_line(lines, ft_strcat(strdup(else_label), strdup(":")));
    add_line(lines, strdup("{"));
    tmp = else_expression;
    while (tmp != NULL)
    {
        add_line(lines, tmp->expression_line);
        prev = tmp;
        tmp = tmp->next;
        free(prev);
    }
    add_line(lines, strdup("}"));
}