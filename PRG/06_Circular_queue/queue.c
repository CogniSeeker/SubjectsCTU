#include <string.h>
 
#include "queue.h"
 
queue_t* create_queue(int capacity) {
    queue_t *q = (queue_t*)malloc(sizeof(queue_t));
    q->capacity = capacity;
    q->first = 0;
    q->last = -1;
    q->size = 0;
    q->data = (void**)malloc(capacity * sizeof(void*));
    if (q->data == NULL)
        exit(EXIT_FAILURE);
 
    return q;
}
void delete_queue(queue_t *queue) {
    free(queue->data);
    free(queue);
}
bool push_to_queue(queue_t *queue, void *data) {
    // Resize the data buffer t0 2x of capacity
    // when the size reaches capacity
    if (queue->size == queue->capacity)
        resize(queue, (2 * queue->capacity));
 
    queue->last = (queue->last + 1) % queue->capacity;
    queue->data[queue->last] = data;
    queue->size++;
 
    return true;
}
void* pop_from_queue(queue_t *queue) {
    if (queue->size == 0)
        return NULL;
 
    void *pop_data = queue->data[queue->first];
    queue->first = (queue->first + 1) % queue->capacity;
    queue->size--;
 
    // Shrink the data buffer to 2/3 of capacity
    // when the size is equal to one-half of the capacity
    if (queue->size == queue->capacity / 2)
        resize(queue, ((2 * queue->capacity) / 3));
 
    return pop_data;
}
void resize(queue_t *queue, int new_capacity) {
    void **new_data = (void **) malloc(new_capacity * sizeof(void *));
    if (new_data == NULL)
        exit(EXIT_FAILURE);
 
    int i;
    for (i = 0; i < queue->size; i++) {
        new_data[i] = queue->data[(queue->first + i) % queue->capacity];
    }
 
    free(queue->data);
    queue->data = new_data;
    queue->first = 0;
    queue->last = (i == 0) ? -1 : i - 1;
    queue->capacity = new_capacity;
}
void* get_from_queue(queue_t *queue, int idx) {
   if (idx < 0 || idx >= queue->size)
      return NULL;
 
   int pos = (queue->first + idx) % queue->capacity;
   return queue->data[pos];
}
//
int get_queue_size(queue_t *queue) {
    return queue->size;
}