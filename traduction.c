#include "structit.h"

void make_declaration(char *name, Type *datatype, int type, int is_pointer, char *filename)
{
    FILE *file = fopen(filename, "a+");
    if (file == NULL)
    {
        printf("Error opening file!\n");
        exit(1);
    }
    // a declarator is : datatype->name identifier ; or datatype->name identifier () ; or  datatype->name identifier ( arguments ) ;
}