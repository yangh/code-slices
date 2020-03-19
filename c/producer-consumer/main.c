/*
 * Producer & Consumer
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

static int end = 0;
static pthread_mutex_t c_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  c_cond = PTHREAD_COND_INITIALIZER;
static int max_len = 3;
static int current_len = 0;
static int pplinline[3] = { 0 };

#define LINE_LEN                3
#define DATA_NUMS		2*1000
#define CONSUMER_THREAD_NUMS	4
#define LOGE printf
#define LOGI printf

void *
consumer_thread (void *data)
{
    int score = 0;

    while (1) {
        pthread_mutex_lock (&c_lock);
	if (current_len == 0) {
            pthread_cond_wait (&c_cond, &c_lock);
	} else {
            LOGE("people in line: %d\n", current_len);
	    current_len--;
            score++;
            pthread_cond_signal (&c_cond);
	}
        pthread_mutex_unlock (&c_lock);

	if (end == 1) break;
    }

    LOGE("pid = %6ld, score = %6d\n", pthread_self(), score);

    return NULL;
}

void *
provider_thread (void *data)
{
    long int nums = * (long int *) data;

    while (nums > 0) {
        pthread_mutex_lock (&c_lock);
	if (current_len == max_len) {
            pthread_cond_wait (&c_cond, &c_lock);
	} else {
	    pinline[current_len] = nums;
	    current_len++;
	    nums--;
            pthread_cond_broadcast (&c_cond);
	}
        pthread_mutex_unlock (&c_lock);
    }

    LOGE("pid = %6ld, remains = %6d\n", pthread_self(), nums);
    return NULL;
}

int main (int argc, char *argv[])
{
    long int data_nums = DATA_NUMS;
    int thread_nums = CONSUMER_THREAD_NUMS;
    pthread_t *c_threads;
    pthread_t p_thread;
    int i;

    LOGE("Threads %6d, datas %6ld\n", thread_nums, data_nums);

    /* Create consumers */
    c_threads = (pthread_t *) malloc (sizeof(pthread_t) * thread_nums);
    for (i = 0; i < thread_nums; i ++) {
        pthread_create (&c_threads[i], NULL, consumer_thread, NULL);
    }

    /* Create producer */
    pthread_create (&p_thread, NULL, provider_thread, &data_nums);

    pthread_join (p_thread, NULL);

    end = 1;
    pthread_mutex_lock (&c_lock);
    pthread_cond_broadcast(&c_cond);
    pthread_mutex_unlock (&c_lock);
    for (i = 0; i < thread_nums; i ++) {
        pthread_join (c_threads[i], NULL);
    }

    free(c_threads);

    return 0;
}

