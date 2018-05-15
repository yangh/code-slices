#include <pthread.h>
#include "list.h"

typedef struct _queue {
    list_t          head;
    pthread_mutex_t lock;
} queue_t;

void q_init  (queue_t *q);
void q_clean (queue_t *q);
int  q_enqueue (queue_t *q, void *data);
int  q_dequeue (queue_t *q, void *data);

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

