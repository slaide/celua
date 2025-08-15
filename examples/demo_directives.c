/* Demo of supported and unsupported preprocessor directives */

// ✅ Supported: Macro definitions
#define MAX_SIZE 1024
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DEBUG

// ✅ Supported: Conditional compilation
#ifdef DEBUG
    #define LOG(msg) printf("DEBUG: " msg "\n")
#else
    #define LOG(msg)
#endif

#if MAX_SIZE > 512
int use_large_buffer = 1;
#endif

int main() {
    int size = MIN(100, MAX_SIZE);
    LOG("Starting program");
    
    // ❌ Unsupported: These get passed through as-is
    #pragma once
    #error "This would be an error in real preprocessor"
    #warning "This would be a warning in GCC"
    
    #undef DEBUG  // ✅ Supported: Macro undefinition
    return 0;
}