#define ARRAY_BASE_MEM   0x80010000
#define RESULTS_BASE_MEM 0x80020000

#define MAX        50 
#define NUM_SORT   5

void cpy_array(int const arr[], int * to_arr, int array_size) {
    for (int i = 0; i < array_size; i++) {
        to_arr[i] = arr[i];
    }
}

void fill_array(int * arr, int array_size) {
    for (int i = 0; i < array_size; i++) {
        arr[i] = array_size - i;
    }
}

void bubble_sort(int a[], int array_size) {
    int i, j, tmp;

    for (i = 0; i < array_size; i++) {
        for (j = 0; j < (array_size - 1 - i); j++) {
            if (a[j + 1] < a[j]) {
                tmp = a[j];
                a[j] = a[j + 1];
                a[j + 1] = tmp;
            }
        }
    }
}

void selection_sort(int numbers[], int array_size) {
    int i, j;
    int min, temp;

    for (i = 0; i < array_size - 1; i++) {
        min = i;
        for (j = i + 1; j < array_size; j++) {
            if (numbers[j] < numbers[min])
                min = j;
        }
        temp = numbers[i];
        numbers[i] = numbers[min];
        numbers[min] = temp;
    }
}

void shell_sort(int numbers[], int array_size) {
    int i, j, increment, temp;

    increment = 3;
    while (increment > 0) {
        for (i = 0; i < array_size; i++) {
            j = i;
            temp = numbers[i];
            while ((j >= increment) && (numbers[j - increment] > temp)) {
                numbers[j] = numbers[j - increment];
                j = j - increment;
            }
            numbers[j] = temp;
        }
        if (increment / 2 != 0)
            increment = increment / 2;
        else if (increment == 1)
            increment = 0;
        else
            increment = 1;
    }
}

void insertion_sort(int numbers[], int array_size) {
    int i, j, index;

    for (i = 1; i < array_size; i++) {
        index = numbers[i];
        j = i;
        while ((j > 0) && (numbers[j - 1] > index)) {
            numbers[j] = numbers[j - 1];
            j = j - 1;
        }
        numbers[j] = index;
    }
}

void q_sort(int numbers[], int left, int right) {
    int pivot, l_hold, r_hold;
    l_hold = left;
    r_hold = right;
    pivot = numbers[left];
    while (left < right) {
        while ((numbers[right] >= pivot) && (left < right))
            right--;
        if (left != right) {
            numbers[left] = numbers[right];
            left++;
        }
        while ((numbers[left] <= pivot) && (left < right))
            left++;
        if (left != right) {
            numbers[right] = numbers[left];
            right--;
        }
    }
    numbers[left] = pivot;
    pivot = left;
    left = l_hold;
    right = r_hold;
    if (left < pivot)
        q_sort(numbers, left, pivot - 1);
    if (right > pivot)
        q_sort(numbers, pivot + 1, right);
}

void quick_sort(int numbers[], int array_size) {
    q_sort(numbers, 0, array_size - 1);
}

int compare(const void * m, const void * n) {
    int * a, * b;
    a = (int * ) m;
    b = (int * ) n;
    if ( * a < * b)
        return -1;
    if ( * a == * b)
        return 0;
    if ( * a > * b)
        return 1;
}

/*
    sort_func_index:
        0: "Selection sort",
        1: "Quicksort",
        2: "Shellsort",
        3: "Insertion sort",
        4: "Bubble sort"
*/
void execute_sort(int const orig[], int copy[], int array_size, int sort_func_index, void( * sort_function)(int[], int)) {
    int validation = 1;

    cpy_array(orig, copy, array_size); //Copy original random array

    for (int i = 1; i < array_size; i++) {
        if (copy[i - 1] <= copy[i])
            validation = 0;
    }

    sort_function(copy, array_size);

    for (int i = 1; i < array_size; i++) {
        if (copy[i - 1] >= copy[i])
            validation = 0;
    }

    if (validation) {
        ((int *) RESULTS_BASE_MEM)[sort_func_index] = 1;
    } else {
        ((int *) RESULTS_BASE_MEM)[sort_func_index] = 2;
    }
}

void main(void) {
    int i;
    int * orig = (int *) ARRAY_BASE_MEM;
    int * copy = (int *) ARRAY_BASE_MEM + MAX;

    /* array that hold sorts that will be performed in sequential order */
    void * function [NUM_SORT] = {
        &selection_sort,
        &quick_sort,
        &shell_sort,
        &insertion_sort,
        &bubble_sort
    };

    fill_array(orig, MAX);

    for (i = 0; i < NUM_SORT; i++) {
        execute_sort(orig, copy, MAX, i, function [i]);
    }

    ((unsigned int*) RESULTS_BASE_MEM)[NUM_SORT] = 0xbeef9988;
}