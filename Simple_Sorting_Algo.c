//Basic Sorting Algorithm

// Sorting Func
void sortingAlgo(int array[], int size) {

    int count = 0;

    //Bubble Sort
    for (int i=0; i<size; i++) {
        for (int j=0; j<size-i; j++) {
            if (array[j] > array[j+1]) {
                int first = array[j];
                array[j] = array[j+1];
                array[j+1] = first;
            }
            // for (int b=0; b<size; b++) {
            //     printf("%d ", array[b]);
            // }
            count += 1;
        }
    }
    //printf("%d ", count);

}

// Main Func
int main() {
    
    // 7 element array
    int array[] = {456, 8, 5, 72, 84, 300, 391};

    // Calling the algorithm
    sortingAlgo(array, 7);
    
    return 0;
}
