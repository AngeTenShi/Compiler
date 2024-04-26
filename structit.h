#ifndef STRUCTIT_H
#define STRUCTIT_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct Structure;
struct Type;

extern struct TypeList *type_list;
extern struct Structure *current_structure;
typedef struct Symbol { // Symbol
    char *name;
    struct Type *data_type; // type of symbol
    int type; // 0 - variable, 1 - function 2- type
    int to_push; // used to not push the same symbol twice
    void *value;
    int is_pointer;
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

typedef struct Type {
    char *name;
    Symbol *symbols;
} Type;

typedef struct TypeList {
    Type *type;
    struct TypeList *next;
} TypeList;

typedef struct Arguments 
{
    char *name;
    int type;
    struct Arguments *next;
} Arguments;

typedef struct Functions {
    char *name;
    char *type_name;
    Arguments *args;
} Functions;


#include "y.tab.h"
void yyerror(const char *s);
extern Type *current_type;
extern Type *current_type_parameter;

/* -----------------Symbol Table------------------*/
SymbolTable *create_symbol_table();
void        push_symbol_table(SymbolTable *symbolTable, SymbolTableStack **symbolTableStack);
void        pop_symbol_table(SymbolTableStack **symbolTableStack);
Symbol      *create_symbol(char *name, Type *data_type, int type, void *value, int to_push, int is_pointer);
void        add_symbol(Symbol *symbol, SymbolTableStack **symbolTableStack);
int         find_symbol(char *name, SymbolTableStack *stack); // if 2 it found in current scope if 1 in previous scope if 0 not found
Symbol      *get_symbol(char *name, SymbolTableStack *stack);
void        *get_variable_value(char *name, SymbolTable *symbolTable);
void        print_symbol_table(SymbolTable *symbolTable);
int         struct_has_member(Symbol *structure, char *name);
int         is_struct(Symbol *symbol);
void        add_type_to_list(TypeList *list, Type *type);
TypeList    *create_type_list();
Type        *get_type(char *name, TypeList *list);
Type        *create_type(char *name, Symbol *symbols);

/* -----------------Syntax Traduction------------------*/
void make_functions(Functions *functions, char *filename);
// void make_declarator


#endif

