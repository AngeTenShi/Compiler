#ifndef STRUCTIT_H
#define STRUCTIT_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct Structure;
struct Type;
struct Function;

extern struct TypeList  *type_list;
extern struct Structure *current_structure;
typedef struct Symbol { // Symbol
    char *name;
    struct Type *data_type; // type of symbol
    int type; // 0 - variable, 1 - function 2- type
    int to_push; // used to not push the same symbol twice
    void *value;
    int is_pointer;
    char *code;
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
} t_type;

typedef struct TypeList {
    t_type *type;
    struct TypeList *next;
} t_typelist;


typedef struct Function {
    char *name;
    t_type *return_type;
    Symbol *arguments;
    int is_pointer;
    int is_extern;
    int pushed;
} t_function;

typedef struct Lines {
    char *line;
    struct Lines *next;
} t_lines; // lines that will be written after a statement

typedef struct Expression {
    char *expression_line;
    struct Expression *next;
} t_expression; // chained list of expressions

#include "y.tab.h"
void yyerror(const char *s);
extern t_type *current_type;
extern t_type *current_type_parameter;

/* -----------------Symbol Table------------------*/
SymbolTable *create_symbol_table();
void        push_symbol_table(SymbolTable *symbolTable, SymbolTableStack **symbolTableStack);
void        pop_symbol_table(SymbolTableStack **symbolTableStack);
Symbol      *create_symbol(char *name, t_type *data_type, int type, void *value, int to_push, int is_pointer);
void        add_symbol(Symbol *symbol, SymbolTableStack **symbolTableStack);
int         find_symbol(char *name, SymbolTableStack *stack); // if 2 it found in current scope if 1 in previous scope if 0 not found
Symbol      *get_symbol(char *name, SymbolTableStack *stack);
void        *get_variable_value(char *name, SymbolTable *symbolTable);
void        print_symbol_table(SymbolTable *symbolTable);
int         struct_has_member(Symbol *structure, char *name);
int         is_struct(Symbol *symbol);
void        add_type_to_list(t_typelist *list, t_type *type);
t_typelist    *create_type_list();
t_type        *get_type(char *name, t_typelist *list);
t_type        *create_type(char *name, Symbol *symbols);

/* -----------------Syntax Traduction------------------*/
void    add_arguments_to_function(Symbol *arguments, t_function **function);
void    write_function(t_function *function, char *filename);
void    reset_function(t_function **function);
void    reset_lines(t_lines **lines);
void    add_line(t_lines **lines, char *content);
void    add_expression(t_expression **expressions, char *content);
t_expression    *remove_last_expression(t_expression **expressions);
void    write_statement(t_lines *lines, char *filename);
void    reset_expressions(t_expression **expressions);
char    *itoa(int value);
char    *ft_strcat(char *src, char *dest);
void    make_for(t_lines **lines, char *init, char *condition, char *increment, t_expression *statement);
void    make_while(t_lines **lines, char *condition, t_expression *expression);
void    make_if(t_lines **lines, char *condition, t_expression *expression);
void    make_if_else(t_lines **lines, char *condition, t_expression *if_expression, t_expression *else_expression);
#endif

