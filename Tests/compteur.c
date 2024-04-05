extern int printd(int i);

int main() {
  int i;
  void test;
  struct ab{
    int a;
    int b;
  };
  struct test2 {
    int c;
    int d;
  };
  for ( i = 0; i < 1000; i = i+1 ) {
    printd(i);
  }
  return 0;
}
