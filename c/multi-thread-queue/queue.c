#include <stdlib.h>
#include <pthread.h>

#include "queue.h"
#include "list.h"
#include "debug.h"

void
q_init (queue_t *q)
{
    list_init(&q->head);
    pthread_mutex_init (&q->lock, NULL);
}

void
q_clean (queue_t *q)
{
    void   *data = NULL;
    int ret = TRUE;

    while (ret) {
        ret = q_dequeue (q, data);
    }
    pthread_mutex_destroy (&q->lock);
}

int
q_enqueue (queue_t *q, void *data)
{
    list_t *list = NULL;

    pthread_mutex_lock (&q->lock);

    list = list_new(data);
    if (list == NULL) {
        LOGE("Failed to alloc new list, no memory");
        pthread_mutex_unlock (&q->lock);
        return FALSE;
    }

    list_add (&q->head, list);

    pthread_mutex_unlock (&q->lock);

    return TRUE;
}

int
q_dequeue (queue_t *q, void *data)
{
    list_t *list = NULL;

    pthread_mutex_lock (&q->lock);

    if (LIST_IS_EMPTY(&q->head)) {
        pthread_mutex_unlock (&q->lock);
        return FALSE;
    }

    list = list_remove(&q->head, q->head.next);
    if (NULL != data) {
	data = list->data;
    }

    list_free(list);
    pthread_mutex_unlock (&q->lock);

    return TRUE;
}

