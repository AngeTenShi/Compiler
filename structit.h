#ifndef STRUCTIT_H
#define STRUCTIT_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct Structure;
extern struct Structure *current_structure;
typedef struct Symbol { // Symbol
    char *name;
    int dataType; // 0 - void, 1 - int, 2 - struct
    int type; // 0 - variable, 1 - function
    void *value;
    struct Structure *structure;
    struct Symbol *next;
} Symbol;

typedef struct SymbolTable { // Symbol table
    struct Symbol *symbols; // all symbols of the tablee
    struct SymbolTable *next;
} SymbolTable;

typedef struct SymbolTableStack { // stack of symbol tables
    struct SymbolTable *top; // top of the stack
} SymbolTableStack;

typedef struct Structure { // Structure with symbols 
    Symbol *all_fields; // variables of the structure
} Structure;


#include "y.tab.h"
void yyerror(const char *s);

SymbolTable *createSymbolTable();
void pushSymbolTable(SymbolTable *symbolTable, SymbolTableStack **symbolTableStack);
void popSymbolTable(SymbolTableStack **symbolTableStack);
Symbol *createSymbol(char *name, int dataType, int type, void *value, Structure *structure);
void addSymbol(Symbol *symbol, SymbolTableStack *symbolTableStack);
int find_symbol(char *name, SymbolTableStack *stack); 
Symbol *getSymbol(char *name, SymbolTableStack *stack);
void *getVariableValue(char *name, SymbolTable *symbolTable);
void printSymbolTable(SymbolTable *symbolTable);
void setVariableValue(char *name, SymbolTableStack *stack, void *value);
void addSymbolToStructure(Symbol *symbol, Structure *structure);
#endif