int foo(int a)
{
    return 1;
}

extern void *malloc(int a);

int main()
{
    struct a 
    {
        int b;
    };

    struct a *name;

    name = malloc(sizeof(name));
    return foo(name);
}