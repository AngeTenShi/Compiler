D                       [0-9]
L                       [a-zA-Z_]
H                       [a-fA-F0-9]
E                       [Ee][+-]?{D}+
FS                      (f|F|l|L)
IS                      (u|U|l|L)*

%option noyywrap
%{
    #include "structit.h"
    extern int yylineno;
    extern int calcul_result;
%}

%%
[ \t\v\n\f\r]           { if(yytext[0] == '\n') yylineno++;  }
"/*"[^"*/"]*"*/"        { }
"extern"                { return EXTERN; }
"int"                   { return INT; }
"goto"                  { return GOTO; }
"void"                  { return VOID; }
"if"                    { return IF; }
"return"                { return RETURN; }
"<="                    { return LE_OP; }
">="                    { return GE_OP; }
"=="                    { return EQ_OP; }
"!="                    { return NE_OP; }
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