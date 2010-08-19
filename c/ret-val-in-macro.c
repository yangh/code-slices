#include <stdio.h>

#define __ret_val_macro(ret) \
    do {                     \
        ret = ret - 1;       \
    } while (0)

#define ret_val_macro(val)        \
    ({                            \
        int __ret = val;          \
        __ret_val_macro(__ret);   \
        __ret;                    \
        })

int main(void)
{
    int val = 10;
    int ret = 0;

    ret = ret_val_macro(val);
    printf ("ret = %d, val = %d\n", ret, val);

    return 0;
}

