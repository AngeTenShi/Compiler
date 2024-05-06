extern int printd( int i );

int foo (int n)
{
  if ( n <= 1 )
    return 1;
  return (n*foo(n-1));
}


int main() {
  
  foo(5);
  return 0;
}
