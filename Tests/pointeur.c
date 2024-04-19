extern int printd( int i );
extern void *malloc( int size );
int main() {
   int *i;
   int *j;
   struct a {
       int i;
       int j;
   };
   i=malloc(sizeof(a));
   j=malloc(sizeof(a));

   *i=4;
  
   printd(*i);

   *j=6;
   printd(*j);

   printd(*j);
   return 0;
}
