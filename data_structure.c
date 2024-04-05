#include "structit.h"

void cleanStructure(Structure *structure)
{
    if (structure != NULL)
    {
        if (structure->symbolTable != NULL)
        {
            if (structure->symbolTable->content != NULL)
            {
                Symbol *tmp = structure->symbolTable->content;
                while (tmp != NULL)
                {
                    Symbol *tmp2 = tmp;
                    tmp = tmp->next;
                    free(tmp2);
                }
            }
            free(structure->symbolTable);
        }
        free(structure);
    }

}

void addSymbol(Symbol *symbol, SymbolTable **symbolTable)
{
    if ((*symbolTable)->content == NULL)
    {
        (*symbolTable)->content = symbol;
        return;
    }
    Symbol *tmp = (*symbolTable)->content;
    while (tmp->next != NULL)
    {
        tmp = tmp->next;
    }
    tmp->next = symbol;
}

int findSymbol(char *name, SymbolTable *symbolTable, int scope)
{
    Symbol *tmp = symbolTable->content;
    while (tmp != NULL)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0)
        {
            if (tmp->dataType == 2)
                return (1);
            if (tmp->scope <= scope)
                return (1);
            else
                return (-1);
        }
        tmp = tmp->next;
    }
    return (0);
}

void printSymbolTable(SymbolTable *symbolTable)
{
    Symbol *tmp = symbolTable->content;
    printf("Symbol Table:\n");
    while (tmp != NULL)
    {  
        char *type = (tmp->type == 0) ? "Variable" : "Function";
        printf("Name: %s, DataType: %d, Type: %s, Content : %s\n", tmp->name, tmp->dataType, type, tmp->value);
        tmp = tmp->next;
    }
    printf("---------------------------\n");
}

Symbol *createSymbol(char *name, int dataType, int type, int scope, void *value, Structure *structure)
{
    Symbol *newSymbol = (Symbol *)malloc(sizeof(Symbol));
    newSymbol->name = name;
    newSymbol->dataType = dataType;
    newSymbol->type = type;
    newSymbol->scope = scope;
    newSymbol->value = value;
    newSymbol->next = NULL;
    if (structure != NULL)
    {
        newSymbol->structure = (Structure *)malloc(sizeof(Structure));
        newSymbol->structure->symbolTable = (SymbolTable*)malloc(sizeof(SymbolTable));
        newSymbol->structure->symbolTable->content = NULL;
        Symbol *tmp = structure->symbolTable->content;
        while (tmp != NULL)
        {
            Symbol *s = createSymbol(tmp->name, tmp->dataType, tmp->type, tmp->scope, tmp->value, tmp->structure);
            addSymbol(s, &newSymbol->structure->symbolTable);
            tmp = tmp->next;
        }
        cleanStructure(structure);
    }
    return (newSymbol);
}

int structHasMember(Structure *structure, char *name)
{
    Symbol *tmp = structure->symbolTable->content;
    while (tmp != NULL)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0)
        {
            return (1);
        }
        tmp = tmp->next;
    }
    return (0);
}

Symbol *getSymbol(char *name, SymbolTable *symbolTable, int scope)
{
    Symbol *tmp = symbolTable->content;
    while (tmp != NULL)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0)
        {
            if (tmp->dataType == 2)
                return (tmp);
            if (tmp->scope <= scope)
                return (tmp);
        }
        tmp = tmp->next;
    }
    return (NULL);
}

void *getVariableValue(char *name, SymbolTable *symbolTable, int scope)
{
    Symbol *tmp = symbolTable->content;
    while (tmp != NULL && tmp->scope <= scope)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0)
        {
            return (tmp->value);
        }
        tmp = tmp->next;
    }
    return (NULL);
}

void pushExpression(void *expression, StackExpression **stack)
{
    StackExpression *newStack = (StackExpression *)malloc(sizeof(StackExpression));
    newStack->expression = expression;
    newStack->next = *stack;
    *stack = newStack;
}

void *popExpression(StackExpression **stack)
{
    StackExpression *tmp = *stack;
    void *expression = tmp->expression;
    *stack = tmp->next;
    free(tmp);
    return expression;
}