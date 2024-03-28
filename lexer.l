D                       [0-9]
L                       [a-zA-Z_]
H                       [a-fA-F0-9]
E                       [Ee][+-]?{D}+
FS                      (f|F|l|L)
IS                      (u|U|l|L)*

%option noyywrap
%{
    #include <stdio.h>
    #include "structit.h"
    extern int yylineno;
%}

%%
[ \t\v\n\f\r]           { printf("Line %d: whitespace character %d\n", yylineno, yytext[0]); if(yytext[0] == '\n') yylineno++; }
"/*"[^"*/"]*"*/"        { } /* ignore comments */
"extern"                { printf("Line %d: extern\n", yylineno); return EXTERN; }
"int"                   { printf("Line %d: int\n", yylineno); return INT; }
"void"                  { printf("Line %d: void\n", yylineno); return VOID; }
"for"                   { printf("Line %d: for\n", yylineno); return FOR; }
"while"                 { printf("Line %d: while\n", yylineno); return WHILE; }
"if"                    { printf("Line %d: if\n", yylineno); return IF; }
"else"                  { printf("Line %d: else\n", yylineno); return ELSE; }
"return"                { printf("Line %d: return\n", yylineno); return RETURN; }
"sizeof"                { printf("Line %d: sizeof\n", yylineno); return SIZEOF; }
"struct"                { printf("Line %d: struct\n", yylineno); return STRUCT; }
"<="                    { printf("Line %d: <=\n", yylineno); return LE_OP; }
">="                    { printf("Line %d: >=\n", yylineno); return GE_OP; }
"=="                    { printf("Line %d: ==\n", yylineno); return EQ_OP; }
"!="                    { printf("Line %d: !=\n", yylineno); return NE_OP; }
"&&"                    { printf("Line %d: &&\n", yylineno); return AND_OP; }
"||"                    { printf("Line %d: ||\n", yylineno); return OR_OP; }
"->"                    { printf("Line %d: ->\n", yylineno); return PTR_OP;}

0{D}+{IS}?              { printf("Line %d: octal not accepted\n", yylineno); yyerror("octal not accepted");}
0[xX]{H}+{IS}?          { printf("Line %d: hexadecimal not accepted\n", yylineno); yyerror("hexadecimal not accepted"); }
{D}+{E}{FS}?            { printf("Line %d: float not accepted\n", yylineno); yyerror("float not accepted"); }
{D}+"."{D}*({E})?{FS}?  { printf("Line %d: float not accepted\n", yylineno); yyerror("float not accepted");}
{D}*"."{D}+({E})?{FS}?  { printf("Line %d: float not accepted\n", yylineno); yyerror("float not accepted");}
L?\"(\\.|[^\\"])*\"     { printf("Line %d: string not accepted\n", yylineno); yyerror("string not accepted");}

{L}({L}|{D})*           { yylval.id = strdup(yytext); printf("Line %d: identifier: %s\n", yylineno, yytext); return IDENTIFIER; }
{D}+{IS}?               { yylval.val = atoi(yytext); printf("Line %d: constant: %s\n", yylineno, yytext); return CONSTANT;}

[\{\}\,\;\(\)\:\=\+\-\/\<\>\&\*]  { printf("Line %d: %c\n", yylineno, yytext[0]); return yytext[0]; }
.                       { printf("Line %d: unknown token: %d\n", yylineno, yytext[0]);}

%%