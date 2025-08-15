#define VERSION 2
#define FEATURE_X
#define DEBUG_LEVEL 3

#if VERSION == 1
#define CONFIG "v1_config.h"
#elif VERSION == 2
#define CONFIG "v2_config.h"
#elif VERSION >= 3
#define CONFIG "v3_config.h"
#else
#define CONFIG "default_config.h"
#endif

#ifdef PRODUCTION
#define LOG_LEVEL 0
#elifdef DEBUG
#define LOG_LEVEL 2
#elif DEBUG_LEVEL > 2
#define LOG_LEVEL 3
#elifndef QUIET_MODE
#define LOG_LEVEL 1
#else
#define LOG_LEVEL 0
#endif

#if VERSION == 2
#ifdef FEATURE_X
#define OPTIMIZED 1
#elifdef FEATURE_Y
#define OPTIMIZED 2
#else
#define OPTIMIZED 0
#endif
#elif VERSION == 3
#define OPTIMIZED 3
#endif

int main() {
    printf("Config: %s\n", CONFIG);
    printf("Log Level: %d\n", LOG_LEVEL);
    printf("Optimized: %d\n", OPTIMIZED);
    return 0;
}