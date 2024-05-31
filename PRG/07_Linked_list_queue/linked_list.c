#include "linked_list.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct queue {
    int data;
    struct queue* next;
} QUEUE;

QUEUE *q = NULL;

// add a new element to the end of the queue
_Bool push(int entry) {
    QUEUE *new_q = (QUEUE*)malloc(sizeof(QUEUE));

    if (!new_q) {
        free(new_q);
        return false;
    }   

    new_q->data = entry;
    new_q->next = NULL;

    QUEUE *tmp = q;
    if (tmp == NULL) {
        q = new_q;
        return true;
    }

    // traverse the queue to find the last node
    while (tmp->next != NULL)
        tmp = tmp->next;

    // add the new node to the end of the queue
    new_q->next = tmp->next;
    tmp->next = new_q;

    return true;
}

// insert a new element in the queue in sorted order
_Bool insert(int entry) {
    QUEUE *new_q = (QUEUE*)malloc(sizeof(QUEUE));

    if (!new_q) {
        free(new_q);
        return false;
    }


    new_q->data = entry;
    new_q->next = NULL;

    QUEUE *tmp = q;

    if (tmp == NULL) {
        q = new_q;
        return true;
    }

    // insert the new node in the queue in sorted order
    if (entry > tmp->data) {
        new_q->next = tmp;
        q = new_q;
        return true;
    }

    // traverse the queue to find the position to insert the new node
    while (tmp->next != NULL && entry < tmp->next->data)
        tmp = tmp->next;

    // insert the new node at the appropriate position
    new_q->next = tmp->next;
    tmp->next = new_q;

    return true;
}

// remove and return the first element of the queue
int pop(void) {
    if (q == NULL)
        return -1;

    QUEUE *tmp = q;
    int value = tmp->data;
    // set the head of the queue to the second node
    q = tmp->next;
    free(tmp);

    return value;
}
// remove all instances of a given element from the queue
_Bool erase(int entry) {
    QUEUE *tmp = q;
    QUEUE *previous = NULL;
    bool entryWasFound = false;
    
    while (tmp != NULL) {
        if (tmp->data == entry) {
            // if the element is the first one, 
            // set the head of the queue to the next element
            if (previous == NULL)
                q = tmp->next;
            // otherwise, set the previous element's next pointer
            //  to the current element's next pointer
            else 
                previous->next = tmp->next;
        
            QUEUE *toBeFreed = tmp;
            tmp = tmp->next;
            free(toBeFreed);
            entryWasFound = true;
        } else {
            previous = tmp;
            tmp = tmp->next;
        }
    }
    return entryWasFound;
}
// get element value with idx from queue
int getEntry(int idx) {
    QUEUE *tmp = q;
    int order = 0;
    if (tmp == NULL)
        return -1;
    if (idx >= 0 && idx < size()) {
        while (tmp->next != NULL) {
            if (order == idx)
                return tmp->data;
            tmp = tmp->next;
            order++;
        }
        if (order == idx)
            return tmp->data;
    }
    return -1;
}
// find out the size of queue
int size(void) {
    int size = 0;
    QUEUE *tmp = q;
    if (tmp == NULL)
        return size;
    else
        size += 1;
    while (tmp->next != NULL) {
        size++;
        tmp = tmp->next;
    }
    return size;
}
// clear queue
void clear() {
    QUEUE *current = q;
    while (current != NULL) {
        QUEUE *temp = current;
        current = current->next;
        free(temp);
    }
    q = NULL;
}