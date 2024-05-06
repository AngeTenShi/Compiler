extern int printd( int i );

int main() {
  int i;
  int j;
  i = 45000;
  j = -123;
  i = i + j;
  printd(45000+(j+0));
  return 0;
}
