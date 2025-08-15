/* Block comment at start */
#define MAX_SIZE 1024
#define ADD(a, b) ((a) + (b))

/*
 * Multi-line block comment
 * with detailed explanation
 */
int main() {
    int x /* inline comment */ = MAX_SIZE;
    int y = ADD(10, /* comment in args */ 20);
    
    // Line comment at end
    printf("Sum: %d\n", x + y);
    
    /* Final comment */ return 0;
}