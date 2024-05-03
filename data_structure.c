#include "structit.h"

SymbolTable *create_symbol_table()
{
    SymbolTable *newSymbolTable = (SymbolTable *)malloc(sizeof(SymbolTable));
    newSymbolTable->symbols = NULL;
    newSymbolTable->next = NULL;
    return (newSymbolTable);
}

void push_symbol_table(SymbolTable *symbolTable, SymbolTableStack **symbolTableStack)
{
    if ((*symbolTableStack)->top == NULL)
    {
        (*symbolTableStack)->top = symbolTable;
        return;
    }
    symbolTable->next = (*symbolTableStack)->top;
    (*symbolTableStack)->top = symbolTable;
}

void pop_symbol_table(SymbolTableStack **symbolTableStack)
{
    if ((*symbolTableStack)->top == NULL)
    {
        printf("Symbol Table Stack is empty a\n");
        return;
    }
    SymbolTable *tmp = (*symbolTableStack)->top;
    (*symbolTableStack)->top = tmp->next;
    free(tmp);
}

void print_symbol_table(SymbolTable *symbolTable)
{
    if (symbolTable == NULL)
    {
        printf("Symbol Table is empty\n");
        return;
    }
    Symbol *tmp = symbolTable->symbols;
    printf("Symbol Table:\n");
    while (tmp != NULL)
    {  
        char *type = (tmp->type == 0) ? "Variable" : (tmp->type == 1) ? "Function" : "Type";
        if (tmp->data_type == NULL)
            printf("Name: %s, DataType: NULL, Type: %s, \n", tmp->name, type);
        else
            printf("Name: %s, DataType: %s, Type: %s, Is pointer : %d \n", tmp->name, tmp->data_type->name, type, tmp->is_pointer);
        tmp = tmp->next;
    }
    printf("---------------------------\n");
}

Symbol *create_symbol(char *name, t_type *data_type, int type, void *value, int to_push, int is_pointer)
{
    Symbol *newSymbol = (Symbol *)malloc(sizeof(Symbol));
    newSymbol->name = name;
    if (data_type != NULL)
        newSymbol->data_type = get_type(data_type->name, type_list);
    else
        newSymbol->data_type = NULL;
    newSymbol->type = type;
    newSymbol->value = value;
    newSymbol->next = NULL;
    newSymbol->to_push = to_push;
    newSymbol->is_pointer = is_pointer;
    return (newSymbol);
}

int struct_has_member(Symbol *structure, char *name)
{
    if (structure == NULL)
        return (0);
    Symbol *tmp = structure;
    while (tmp != NULL)
    {
        if (tmp->name != NULL)
        {
            if (strncmp(tmp->name, name, strlen(name)) == 0 && strlen(tmp->name) == strlen(name))
            {
                return (1);
            }
        }
        tmp = tmp->next;
    }
    return (0);
}

void *get_variable_value(char *name, SymbolTable *symbolTable)
{
    Symbol *tmp = symbolTable->symbols;
    while (tmp != NULL)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0 && strlen(tmp->name) == strlen(name))
        {
            return (tmp->value);
        }
        tmp = tmp->next;
    }
    return (NULL);
}

void add_symbol(Symbol *symbol, SymbolTableStack **symbolTableStack)
{
    if (symbol == NULL)
        return;
    if ((*symbolTableStack)->top == NULL)
    {
        printf("Symbol Table Stack is empty b\n");
        return;
    }
    if (symbol->to_push == 0)
    {
        free(symbol);
        return;
    }
    if (find_symbol(symbol->name, *symbolTableStack) == 2)
    {
        printf("Symbol %s already exists\n", symbol->name);
        free(symbol);
        return;
    }
    SymbolTable *symbolTable = (*symbolTableStack)->top;
    if (symbolTable->symbols == NULL)
        symbolTable->symbols = symbol;
    else
    {
        Symbol *tmp = symbolTable->symbols;
        while (tmp->next != NULL)
        {
            tmp = tmp->next;
        }
        tmp->next = symbol;
    }
}

int find_symbol(char *name, SymbolTableStack *stack)
{
    SymbolTable *tmp = stack->top;
    Symbol *tmp2 = NULL;
    while (tmp != NULL)
    {
        tmp2 = tmp->symbols;
        while (tmp2 != NULL)
        {
            if (strncmp(tmp2->name, name, strlen(name)) == 0 && strlen(tmp2->name) == strlen(name))
                break;
            tmp2 = tmp2->next;
        }
        tmp = tmp->next;
    }
    if (tmp2 != NULL)
    {
        if (tmp == stack->top)
            return (2);
        else
            return (1);
    }
    return (0);
}

Symbol *get_symbol(char *name, SymbolTableStack *stack)
{
    SymbolTable *tmp = stack->top;
    while (tmp != NULL)
    {
        Symbol *tmp2 = tmp->symbols;
        while (tmp2 != NULL)
        {
            if (strncmp(tmp2->name, name, strlen(name)) == 0 && strlen(tmp2->name) == strlen(name))
                return (tmp2);
            tmp2 = tmp2->next;
        }
        tmp = tmp->next;
    }
    return (NULL);
}

t_typelist *create_type_list()
{
    t_typelist *newTypeList = (t_typelist *)malloc(sizeof(t_typelist));
    t_type *new_type = (t_type *)malloc(sizeof(t_type));
    new_type->name = "int";
    new_type->symbols = NULL;
    newTypeList->type = new_type;
    t_type *new_type2 = (t_type *)malloc(sizeof(t_type));
    new_type2->name = "void";
    new_type2->symbols = NULL;
    newTypeList->next = malloc(sizeof(t_typelist));
    newTypeList->next->type = new_type2;
    newTypeList->next->next = NULL;
    return (newTypeList);
}

t_type    *get_type(char *name, t_typelist *typeList)
{
    t_typelist *tmp = typeList;
    while (tmp != NULL)
    {
        if (strncmp(tmp->type->name, name, strlen(name)) == 0 && strlen(tmp->type->name) == strlen(name))
            return (tmp->type);
        tmp = tmp->next;
    }
    return (NULL);
}

t_type    *create_type(char *name, Symbol *symbols)
{
    t_type *newType = (t_type *)malloc(sizeof(t_type));
    newType->name = name;
    newType->symbols = symbols;
    return (newType);
}

void    add_type_to_list(t_typelist *typeList, t_type *type)
{
    t_typelist *tmp = typeList;
    while (tmp->next != NULL)
    {
        tmp = tmp->next;
    }
    tmp->next = malloc(sizeof(t_typelist));
    tmp->next->type = type;
    tmp->next->next = NULL;
}

int is_struct(Symbol *symbol)
{
    // if data_type->name != int and data_type->name != void then it's a struct
    if (symbol->data_type == NULL)
        return (0);
    if ((strncmp(symbol->data_type->name, "int", 3) == 0 && strlen(symbol->data_type->name) == 3) || (strncmp(symbol->data_type->name, "void", 4) == 0 && strlen(symbol->data_type->name) == 4))
        return (0);
    return (1);
}

void    reset_function(t_function **function)
{
    if (function == NULL)
        return;
    if (*function == NULL)
        return;
    (*function)->name = NULL;
    (*function)->return_type = NULL;
    (*function)->arguments = NULL;
    (*function)->is_pointer = 0;
    (*function)->is_extern = 0;
    (*function)->pushed = 0;
}