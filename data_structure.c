#include "structit.h"

SymbolTable *createSymbolTable()
{
    SymbolTable *newSymbolTable = (SymbolTable *)malloc(sizeof(SymbolTable));
    newSymbolTable->symbols = NULL;
    newSymbolTable->next = NULL;
    return (newSymbolTable);
}

void pushSymbolTable(SymbolTable *symbolTable, SymbolTableStack **symbolTableStack)
{
    SymbolTableStack *newSymbolTableStack = (SymbolTableStack *)malloc(sizeof(SymbolTableStack));
    newSymbolTableStack->top = symbolTable;
    *symbolTableStack = newSymbolTableStack;
}

// pop the top symboltable and update the top of the stack
void popSymbolTable(SymbolTableStack **symbolTableStack)
{
    SymbolTable *tmp = (*symbolTableStack)->top;
    (*symbolTableStack)->top = tmp->next;
    free(tmp);
}

void    setVariableValue(char *name, SymbolTableStack *stack, void *value)
{
    Symbol *to_update = getSymbol(name, stack);
    to_update->value = value;
}

void cleanStructure(Structure *structure)
{
    if (structure != NULL)
    {
        if (structure->all_fields != NULL)
        {
                Symbol *tmp = structure->all_fields;
                while (tmp != NULL)
                {
                    Symbol *tmp2 = tmp;
                    tmp = tmp->next;
                    free(tmp2);
                }
        }
        free(structure);
    }

}

void printSymbolTable(SymbolTable *symbolTable)
{
    Symbol *tmp = symbolTable->symbols;
    printf("Symbol Table:\n");
    while (tmp != NULL)
    {  
        char *type = (tmp->type == 0) ? "Variable" : "Function";
        printf("Name: %s, DataType: %d, Type: %s, Content : %s\n", tmp->name, tmp->dataType, type, tmp->value);
        tmp = tmp->next;
    }
    printf("---------------------------\n");
}

Symbol *createSymbol(char *name, int dataType, int type, void *value, Structure *structure)
{
    Symbol *newSymbol = (Symbol *)malloc(sizeof(Symbol));
    newSymbol->name = name;
    newSymbol->dataType = dataType;
    newSymbol->type = type;
    newSymbol->value = value;
    newSymbol->next = NULL;
    if (structure != NULL)
    {
        newSymbol->structure = (Structure *)malloc(sizeof(Structure));
        newSymbol->structure->all_fields = (Symbol*)malloc(sizeof(Symbol));
        Symbol *tmp = structure->all_fields;
        while (tmp != NULL)
        {
            Symbol *copy_symbol_from_tmp = createSymbol(tmp->name, tmp->dataType, tmp->type, tmp->value, tmp->structure);
            addSymbolToStructure(copy_symbol_from_tmp, newSymbol->structure);
            tmp = tmp->next;
        }
        cleanStructure(structure);
    }
    return (newSymbol);
}

int structHasMember(Structure *structure, char *name)
{
    Symbol *tmp = structure->all_fields;
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

void *getVariableValue(char *name, SymbolTable *symbolTable)
{
    Symbol *tmp = symbolTable->symbols;
    while (tmp != NULL)
    {
        if (strncmp(tmp->name, name, strlen(name)) == 0)
        {
            return (tmp->value);
        }
        tmp = tmp->next;
    }
    return (NULL);
}

void addSymbol(Symbol *symbol, SymbolTableStack *symbolTableStack)
{
    if (find_symbol(symbol->name, symbolTableStack) == 2)
    {
        printf("Symbol %s already exists\n", symbol->name);
        free(symbol);
        return;
    }
    SymbolTable *symbolTable = symbolTableStack->top;
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
    Symbol *tmp2;
    while (tmp != NULL)
    {
        Symbol *tmp2 = tmp->symbols;
        while (tmp2 != NULL)
        {
            if (strncmp(tmp2->name, name, strlen(name)) == 0)
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

Symbol *getSymbol(char *name, SymbolTableStack *stack)
{
    SymbolTable *tmp = stack->top;
    while (tmp != NULL)
    {
        Symbol *tmp2 = tmp->symbols;
        while (tmp2 != NULL)
        {
            if (strncmp(tmp2->name, name, strlen(name)) == 0)
                return (tmp2);
            tmp2 = tmp2->next;
        }
        tmp = tmp->next;
    }

}

void addSymbolToStructure(Symbol *symbol, Structure *structure)
{
    if (structure->all_fields == NULL)
    {
        structure->all_fields = symbol;
    }
    else
    {
        Symbol *tmp = structure->all_fields;
        while (tmp->next != NULL)
        {
            tmp = tmp->next;
        }
        tmp->next = symbol;
    }
}