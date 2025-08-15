# 100 "input.c"
#define COMPLEX_MACRO(x) \
    ((x) * 2 + 1)

int main() {
    int value = \
        COMPLEX_MACRO(5);
    
    return 0;
}