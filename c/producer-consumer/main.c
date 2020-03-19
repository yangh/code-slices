/*
 * Producer & Consumer
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define LOGI printf
#if DEBUG
#define LOGD printf
#else
#define LOGD(...)
#endif

#define BUFFER_MAX       3
#define CONSUMER_NUMS    4
#define DATA_NUMS        2*100*100

static pthread_mutex_t c_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  c_cond = PTHREAD_COND_INITIALIZER;
static int end = 0;

static long int buffer[BUFFER_MAX] = { 0 };
static int current = 0;
#define BUFFER_IS_FULL()  (current == BUFFER_MAX)
#define BUFFER_IS_EMPTY() (current == 0)

static void * consumer_thread (void *data)
{
    int score = 0;

    while (!end) {
        pthread_mutex_lock (&c_lock);
        if (BUFFER_IS_EMPTY()) {
            pthread_cond_wait (&c_cond, &c_lock);
        } else {
            LOGD("Buffer len: %d, current: %ld\n", current, buffer[current - 1]);
            current--;
            score++;
            pthread_cond_signal (&c_cond);
        }
        pthread_mutex_unlock (&c_lock);
    }

    LOGI("consumer = %ld, score = %6d\n", pthread_self(), score);
    return NULL;
}

static void * producer_thread (void *data)
{
    long int nums = * (long int *) data;

    while (nums > 0) {
        pthread_mutex_lock (&c_lock);
        if (BUFFER_IS_FULL()) {
            pthread_cond_wait (&c_cond, &c_lock);
        } else {
            buffer[current] = nums;
            current++;
            nums--;
            pthread_cond_signal (&c_cond);
        }
        pthread_mutex_unlock (&c_lock);
    }

    LOGI("producer = %6ld, remains = %ld\n", pthread_self(), nums);
    return NULL;
}

int main (int argc, char *argv[])
{
    long int data_nums = DATA_NUMS;
    int    thread_nums = CONSUMER_NUMS;
    pthread_t *c_threads;
    pthread_t p_thread;
    int i;

    LOGI("Consumer threads %d, datas %ld\n", thread_nums, data_nums);

    /* Create consumers */
    c_threads = (pthread_t *) malloc (sizeof(pthread_t) * thread_nums);
    for (i = 0; i < thread_nums; i ++) {
        pthread_create (&c_threads[i], NULL, consumer_thread, NULL);
    }

    /* Create producer */
    pthread_create (&p_thread, NULL, producer_thread, &data_nums);
    pthread_join (p_thread, NULL);

    end = 1;
    for (i = 0; i < thread_nums; i ++) {
        pthread_mutex_lock (&c_lock);
        pthread_cond_broadcast (&c_cond);
        pthread_mutex_unlock (&c_lock);
        pthread_join (c_threads[i], NULL);
    }

    free(c_threads);

    return 0;
}

