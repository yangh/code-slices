/*
 * flexiable-string-array.c - demo only 
 *
 * Author: pen9u1n
 *
 * More information: http://is.gd/dDcRu
 * 
 * History:
 *   2010-07-23 Initial version.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TEXT_HELLOWORLD "Hello World!"

/* Log domain */
#define LOG_TAG "fsa"

/* Log utility */
#ifndef LOG_TAG
 #define LOG_TAG "unknown"
#endif

#define LOG(level, msg) printf("%c/%s %s:%d %s\n", level, LOG_TAG, __FILE__, __LINE__, msg)

#ifndef DEBUG
 #define LOGI(...)
 #define LOGD(...)
#else
 #define LOGI(msg) LOG('I', msg)
 #define LOGD(msg) LOG('D', msg)
#endif /* DEBUG */

#define LOGE(msg) LOG('E', msg)

#define MAX_DATA_LEN 256

struct helloworld_t
{
    int  length;
    char data[0];
};

struct helloworld_t * helloworld_new  (void *data, size_t length);
void                  helloworld_free (struct helloworld_t *p);
void                  helloworld_dump (struct helloworld_t *p);

struct helloworld_t *
helloworld_new (void *data, size_t length)
{
    struct helloworld_t *p = NULL;

    if (data == NULL) {
        return NULL;
    }

    p = (struct helloworld_t *) malloc(sizeof(struct helloworld_t) + length);

    if (p == NULL) {
        LOGE("Out of memory.");
        return NULL;
    }

    LOGD ("New helloworld_t instance");

    p->length = length;

    memset (p->data, 0, length);
    memcpy (p->data, data, length);

    return p;
}

void
helloworld_dump (struct helloworld_t *p)
{
    char buff[MAX_DATA_LEN + 1];
    int len = 0;

    if (p == NULL) {
        return;
    }

    len = p->length > MAX_DATA_LEN ? MAX_DATA_LEN : p->length;
    memcpy (buff, p->data, len);
    buff[len] = '\0';

    LOGD(buff);
}

void
helloworld_free (struct helloworld_t *p)
{
    LOGD ("Free helloworld_t instance");

    if (p == NULL) {
        return;
    }

    /* FIXME: How to free the real data allocated by malloc? */
    /* free ((void *) p->data); */
#if 1
    free (p);
#endif
}

int main(int argc, char *argv[])
{
    struct helloworld_t *p = NULL;

    p = helloworld_new (TEXT_HELLOWORLD, sizeof(TEXT_HELLOWORLD));
    helloworld_dump (p);
    helloworld_free (p);
    p = NULL;

    return 0;
}

