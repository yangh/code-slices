#include <stdlib.h>
#include "list.h"

void list_init (list_t *list)
{
	if (NULL != list) {
		list->prev = list;
		list->next = list;
		list->data = NULL;
	}
}

list_t* list_new  (void *data)
{
	list_t* list = NULL;

	list = (list_t *) malloc (sizeof(list_t));
	if (NULL != list) {
		list_init (list);
		list->data = data;
	}

	return list;
}

void list_free (list_t *node)
{
	if (NULL != node) {
		node->prev = NULL;
		node->next = NULL;
		node->data = NULL;
		free(node);
	}
}

list_t* list_remove (list_t* list, list_t *node)
{
	list_t* prev, * next;

	if (LIST_IS_EMPTY(list)) {
		return node;
	}

        prev = node->prev;
        next = node->next;
        prev->next = next;
        next->prev = prev;

	node->prev = node;
	node->next = node;

	return node;
}

list_t* list_add (list_t* list, list_t *node)
{
	if (LIST_IS_EMPTY(list)) {
		list->next = node;
		list->prev = node;
		node->prev = list;
		node->next = list;
		return list;
	}

	list->prev->next = node;
	node->prev = list->prev;
	node->next = list;
        list->prev = node;

	return list;
}

int list_dump (list_t* list, LIST_DUMP_FUNC dump_func)
{
	int count = 0;
	list_t* head = NULL;
	list_t* end;

	if (LIST_IS_EMPTY(list)) {
		return count;
	}

	end = list;
	head = list->next;
	do {
		dump_func(head->data);
		head = head->next;
		count++;
	} while (head != end);

	return count;
}

list_t* list_remove_data (list_t* list, void *data);
list_t* list_add_data    (list_t* list, void *data);
int     list_length      (list_t* list);
list_t* list_find        (list_t* list, list_t *node);
list_t* list_find_data   (list_t* list, void *data);
