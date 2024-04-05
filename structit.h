#ifndef STRUCTIT_H
#define STRUCTIT_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct Structure;
extern struct Structure *currentStructure;
typedef struct Symbol {
    char *name;
    int dataType; // 0 - void, 1 - int, 2 - struct
    int type; // 0 - variable, 1 - function
    int scope;
    void *value;
    struct Structure *structure;
    struct Symbol *next;
} Symbol;

typedef struct SymbolTable {
    struct Symbol *content;
} SymbolTable;

typedef struct Structure {
    SymbolTable *symbolTable;
} Structure;

typedef struct StackExp {
    void *expression;
    struct StackExp *next;
} StackExpression;

#include "y.tab.h"
void yyerror(const char *s);


Symbol *createSymbol(char *name, int dataType, int type, int scope, void *value, Structure *structure);
void addSymbol(Symbol *symbol, SymbolTable **symbolTable);
int findSymbol(char *name, SymbolTable *symbolTable, int scope); // if -1 found but in not visible scope
Symbol *getSymbol(char *name, SymbolTable *symbolTable, int scope);
void *getVariableValue(char *name, SymbolTable *symbolTable, int scope);
void printSymbolTable(SymbolTable *symbolTable);
void setVariableValue(char *name, SymbolTable *symbolTable, void *value);
void pushExpression(void *expression, StackExpression **stack);
void *popExpression(StackExpression **stack);


#endif