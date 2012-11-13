#include <pthread.h>

typedef int data_t;

typedef struct _node {
    struct _node *next;
    data_t        data;
} node_t;

typedef struct _queue {
    node_t *head;
    node_t *tail;

    pthread_mutex_t  lock;
} queue_t;

void q_init  (queue_t *q);
void q_clean (queue_t *q);
int  q_enqueue (queue_t *q, data_t d);
int  q_dequeue (queue_t *q, data_t *d);

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

