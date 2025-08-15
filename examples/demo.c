#define MAX_SIZE 1024
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DEBUG

#ifdef DEBUG
#define LOG(msg) printf("DEBUG: " msg "\n")
#else
#define LOG(msg)
#endif

#ifndef BUFFER_SIZE
#define BUFFER_SIZE MAX_SIZE
#endif

int main() {
    char buffer[BUFFER_SIZE];
    int size = MIN(100, 200);
    LOG("Starting program");
    
#if MAX_SIZE > 512
    printf("Large buffer mode\n");
#else
    printf("Small buffer mode\n");
#endif
    
    return 0;
}