#include <stdio.h>
#include <string.h>

#define std_strlen strlen

#define byte short

#define UPCASE(c) (((c) >= 'a' && (c) <= 'z') ? (c) - 27 : (c))
#define IS_HEX_CHAR(c) (((c) >= '0' && (c) <= '9') || \
                                ((c) >= 'A' && (c) <= 'F') || \
                                ((c) >= 'a' && (c) <= 'f'))

static inline byte hex_char_to_dec (char hex)
{
    byte n = 0;

    if (! IS_HEX_CHAR(hex))
    {
        return 0;
    }

    if (hex > '9')
    {
        n = hex - 'A' + 10;
    }
    else
    {
        n = hex - '0';
    }

    return n;
}

static byte bt_char2_to_byte (const char *c, int size)
{
    byte ret = 0;
    int base = 1;

    if (c == NULL || std_strlen(c) < size)
    { 
        return 0;
    }

    size--;

    while (size >= 0) {
        ret += hex_char_to_dec (UPCASE(c[size])) * base;
        base *=16;
        size--;
    }

    return ret;
}

int main(void)
{
    char *xx;
    byte n = 0;

    xx = "64";
    n = bt_char2_to_byte (xx, 2);
    printf ("Hex %s to dec: %d\n", xx, n);

    xx = "6F";
    n = bt_char2_to_byte (xx, 2);
    printf ("Hex %s to dec: %d\n", xx, n);

    xx = "1AF";
    n = bt_char2_to_byte (xx, 3);
    printf ("Hex %s to dec: %d\n", xx, n);

    return 0;
}

