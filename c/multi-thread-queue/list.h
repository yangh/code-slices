#ifndef __LIST_H
#define __LIST_H

#include <unistd.h>

/* Double linked list */
typedef struct _list {
    struct _list* prev;
    struct _list* next;
    void *        data;
} list_t;

#define LIST_INITIALIZER { NULL, NULL, NULL }

void    list_init (list_t *list);
list_t* list_new  (void *data);
void    list_free (list_t *node);
list_t* list_remove      (list_t* list, list_t *node);
list_t* list_remove_data (list_t* list, void *data);
list_t* list_add         (list_t* list, list_t *node);
list_t* list_add_data    (list_t* list, void *data);
int     list_length      (list_t* list);
list_t* list_find        (list_t* list, list_t *node);
list_t* list_find_data   (list_t* list, void *data);

#define LIST_IS_EMPTY(list) ((list)->prev == (list) && \
		             (list)->next == (list))

typedef void (LIST_DUMP_FUNC)(void *);

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#endif /* __LIST_H */
