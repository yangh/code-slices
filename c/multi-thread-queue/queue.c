#include <stdlib.h>
#include <pthread.h>

#include "queue.h"
#include "debug.h"

void
q_init (queue_t *q)
{
    q->head = q->tail = NULL;
    pthread_mutex_init (&q->lock, NULL);
}

void
q_clean (queue_t *q)
{
    node_t *node = NULL;

    pthread_mutex_lock (&q->lock);

    node = q->head;
    while (q->head != NULL) {
        node = q->head;
        q->head = node->next;
        free (node);
    }

    pthread_mutex_unlock (&q->lock);
    pthread_mutex_destroy (&q->lock);
}

int
q_enqueue (queue_t *q, data_t d)
{
    node_t *node = NULL;

    pthread_mutex_lock (&q->lock);

    node = (node_t *) malloc (sizeof(node_t));
    if (node == NULL) {
        LOGE("Failed to alloc new node, no memory");
        pthread_mutex_unlock (&q->lock);
        return FALSE;
    }

    node->data = d;
    node->next = NULL;

    if (q->head == NULL) {
        q->head = q->tail = node;
    } else {
        q->tail->next = node;
        q->tail = node;
    }

    pthread_mutex_unlock (&q->lock);

    return TRUE;
}

int
q_dequeue (queue_t *q, data_t *d)
{
    node_t *node = NULL;

    pthread_mutex_lock (&q->lock);

    if (q->head == NULL) {
        pthread_mutex_unlock (&q->lock);
        return FALSE;
    }

    node = q->head;
    *d = node->data;
    q->head = node->next;

    pthread_mutex_unlock (&q->lock);
    free(node);

    return TRUE;
}

