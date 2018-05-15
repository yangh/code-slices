/*
 * Test program for multi-thread queue
 *
 * Author: Yang Hong
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

#include "queue.h"
#include "debug.h"

static queue_t g_queue;
static int     g_thread_count = 0;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  g_cond = PTHREAD_COND_INITIALIZER;

static pthread_mutex_t t_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  t_cond = PTHREAD_COND_INITIALIZER;

#define DATA_NUMS 2*1000*1000
#define CONSUMER_THREAD_NUMS 8

void *
consumer_thread (void *data)
{
    int ret = TRUE;
    int count = 0;
    queue_t *q = (queue_t *) data;
    int value;

    pthread_mutex_lock (&t_lock);
    g_thread_count++;
    pthread_cond_signal (&t_cond);
    pthread_mutex_unlock (&t_lock);

    pthread_mutex_lock (&g_lock);
    pthread_cond_wait (&g_cond, &g_lock);
    pthread_mutex_unlock (&g_lock);

    while (ret) {
        count++;
        ret = q_dequeue (q, &value);
    }

    LOGE("pid = %6ld, count = %6d\n", pthread_self(), count);

    return NULL;
}

void *
provider_thread (void *data)
{
    int nums = * (int *) data;

    /* Wait until all thread is ready */
    while (g_thread_count < nums) {
        usleep(1000);
    }

    /* Wake up all consumer thread */
    pthread_mutex_lock (&g_lock);
    pthread_cond_broadcast (&g_cond);
    pthread_mutex_unlock (&g_lock);

    return NULL;
}

void list_dump_func(void *data)
{
    printf("%d\n", (int)data);
}

int main (int argc, char *argv[])
{
    int node_nums = DATA_NUMS;
    int thread_nums = CONSUMER_THREAD_NUMS;
    pthread_t *c_threads;
    pthread_t p_thread;
    int i;

    printf ("Hello threads.\n");

    if (argc > 1) {
        node_nums = atoi(argv[1]);
    }

    if (argc > 2) {
        thread_nums = atoi(argv[2]);
    }

    LOGE("Threads %6d, queue nodes %6d\n", thread_nums, node_nums);

    pthread_create (&p_thread, NULL, provider_thread, &thread_nums);

    q_init (&g_queue);
    for (i = 0; i < node_nums; i ++) {
        q_enqueue (&g_queue, (void*) i);
    }

    //list_dump(&g_queue.head, list_dump_func);

    c_threads = (pthread_t *) malloc (sizeof(pthread_t) * thread_nums);
    for (i = 0; i < thread_nums; i ++) {
        pthread_create (&c_threads[i], NULL, consumer_thread, &g_queue);
    }

    pthread_join (p_thread, NULL);
    for (i = 0; i < thread_nums; i ++) {
        pthread_join (c_threads[i], NULL);
    }

    q_clean (&g_queue);

    return 0;
}

