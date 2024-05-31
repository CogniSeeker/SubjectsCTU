#include "queue.h"

#include <stdlib.h>
#include <stdbool.h>

// define a node structure for the linked list
typedef struct Node {
    void* data;
    struct Node* next;
} Node;

// define a queue structure using the linked list
typedef struct {
    int size;
    Node* head;
    int (*compare)(const void*, const void*);
    void (*clear)(void*);
} QUEUE;

// creates a new empty queue and returns a pointer to it
void* create() {
    QUEUE* queue = (QUEUE*) malloc(sizeof(QUEUE));
    queue->head = NULL;
    queue->size = 0;
    queue->compare = NULL;
    queue->clear = NULL;
    return queue;
}

// clears all elements from the queue and frees memory used by them
void clear(void *queue_ptr) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    Node* current = queue->head;
    while (current != NULL) {
        Node* tmp = current;
        current = current->next;
        if (queue->clear != NULL && tmp->data != NULL) {
            queue->clear(tmp->data);
        } else {
            free(tmp->data);
        }
        free(tmp);
    }
    queue->head = NULL;
    queue->size = 0;
}

// adds a new element to the end of the queue
bool push(void *queue_ptr, void *entry) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    if (entry == NULL) {
        return false;
    }
    Node* new_node = (Node*) malloc(sizeof(Node));
    new_node->data = entry;
    new_node->next = NULL;
    if (queue->size == 0) {
        queue->head = new_node;
        queue->size++;
        return true;
    }
    Node* current = queue->head;
    while (current->next != NULL)
        current = current->next;
    new_node->next = current->next;
    current->next = new_node;
    queue->size++;
    return true;
}

// removes and returns the first element from the queue
void* pop(void *queue_ptr) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    if (queue->size == 0) {
        return NULL;
    }
    Node* old_head = queue->head;
    void* data = old_head->data;
    queue->head = old_head->next;
    free(old_head);
    queue->size--;
    return data;
}

// inserts a new element into the queue at the correct position based on the compare function
bool insert(void *queue_ptr, void *entry) {
    QUEUE *queue = (QUEUE *)queue_ptr;

    // Check for invalid input
    if (entry == NULL || queue->compare == NULL) {
        return false;
    }

    // Create new node with the provided data
    Node* new_node = (Node*) malloc(sizeof(Node));
    new_node->data = entry;
    new_node->next = NULL;

    // Special case: empty queue
    if (queue->size == 0) {
        queue->head = new_node;
        queue->size++;
        return true;
    }

    // Find the correct position to insert the new node
    Node* current = queue->head;
    Node* previous = NULL;

    while (current != NULL) {
        // If the new node is greater or equal than the current node, break the loop
        if ((queue->compare(entry, current->data) == 1) || \
            (queue->compare(entry, current->data) == 0)) {
            break;
        }
        previous = current;
        current = current->next;
    }

    // Insert the new node at the correct position
    if (previous == NULL) {
        new_node->next = queue->head;
        queue->head = new_node;
    } else {
        new_node->next = current;
        previous->next = new_node;
    }

    queue->size++;
    return true;
}
// Removes the first occurrence of the specified entry from the queue.
// Returns true if the entry was found and removed, false otherwise.
bool erase(void *queue_ptr, void *entry) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    Node* current = queue->head;
    Node* previous = NULL;
    bool erased = false;

    while (current != NULL) {
        if (queue->compare(entry, current->data) == 0) {
            Node* to_delete = current;
            if (previous == NULL) {
                queue->head = current->next;
            } else {
                previous->next = current->next;
            }
            current = current->next;

            if (queue->clear != NULL) {
                queue->clear(to_delete->data);
            } else {
                free(to_delete->data);
            }
            free(to_delete);
            queue->size--;
            erased = true;
        } else {
            previous = current;
            current = current->next;
        }
    }
    return erased;
}
// Returns a pointer to the entry at the specified index in the queue.
// Returns NULL if the index is out of bounds.
void* getEntry(const void *queue_ptr, int idx) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    if (idx < 0 || idx >= queue->size) {
        return NULL;
    }
    Node* current = queue->head;
    for (int i = 0; i < idx; i++) {
        current = current->next;
    }
    return current->data;
}
// Returns the number of elements in the queue.
int size(const void *queue_ptr) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    return queue->size;
}
// Sets the compare function for the queue.
void setCompare(void *queue_ptr, int (*compare)(const void *, const void *)) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    queue->compare = compare;
}
// Sets the clear function for the queue.
// The clear function is called when an element is removed from the queue.
void setClear(void *queue_ptr, void (*clear)(void *)) {
    QUEUE *queue = (QUEUE *)queue_ptr;
    queue->clear = clear;
}