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
    extern int calcul_result;
%}

%%
[ \t\v\n\f\r]           { if(yytext[0] == '\n') { yylineno++; calcul_result = 0; current_type = NULL; current_type_parameter = NULL; }  } /* reset local calcul result for each line */
"/*"[^"*/"]*"*/"        { } /* ignore comments */
"extern"                { return EXTERN; }
"int"                   { return INT; }
"void"                  { return VOID; }
"for"                   { return FOR; }
"while"                 { return WHILE; }
"if"                    { return IF; }
"else"                  { return ELSE; }
"return"                { return RETURN; }
"sizeof"                { return SIZEOF; }
"struct"                { return STRUCT; }
"<="                    { return LE_OP; }
">="                    { return GE_OP; }
"=="                    { return EQ_OP; }
"!="                    { return NE_OP; }
"&&"                    { return AND_OP; }
"||"                    { return OR_OP; }
"->"                    { return PTR_OP;}
"{"                     { return '{';}
"}"                     { return '}';}
0{D}+{IS}?              { yyerror("octal not accepted");}
0[xX]{H}+{IS}?          { yyerror("hexadecimal not accepted"); }
{D}+{E}{FS}?            { yyerror("float not accepted"); }
{D}+"."{D}*({E})?{FS}?  { yyerror("float not accepted");}
{D}*"."{D}+({E})?{FS}?  { yyerror("float not accepted");}
L?\"(\\.|[^\\"])*\"     { yyerror("string not accepted");}

{L}({L}|{D})*           { yylval.id = strdup(yytext); return IDENTIFIER; }
{D}+{IS}?               { yylval.val = atoi(yytext); return CONSTANT;}

[\;\(\)\:\=\+\-\/\<\>\&\*\,]  { return yytext[0]; }
.                       { printf("Mystery character %s\n", yytext); }

%%