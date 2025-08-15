#include "local_header.h"
#include <system_header.h>

int main() {
    int x = LOCAL_CONSTANT;
    int y = LOCAL_FUNC(5);
    system_int_t size = SYSTEM_MAX_SIZE;
    printf("Version: %s\n", SYSTEM_VERSION);
    return 0;
}