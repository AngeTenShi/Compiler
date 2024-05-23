extern int printd( int i );

struct a{
  int x;
  int y;
};

int foo (int n)
{
  struct a b;
  int n;
  if ( n <= 1 )
    return 1;
  return (n(1)*foo(n-1));
}


int main() {
  
  foo(5);
  return 0;
}
