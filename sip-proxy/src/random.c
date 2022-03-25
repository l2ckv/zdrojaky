#include <stdlib.h>
#include <time.h>
#include "random.h"

/* allowable characters */
char AC[] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z'
};

#define N_ALLOWABLE sizeof(AC)/sizeof(AC[0])

void init_random_generator()
{
    srand(time(NULL));
}

char *get_random_string(int length)
{
    static char nonce[1024];
    int i, r_num;
    for (i = 0; i < length; i++)
    {
        r_num = rand()%N_ALLOWABLE;
        nonce[i] = AC[r_num];
    }
    return nonce;
}

int get_random_int(int min, int max)
{
    return min + (rand()%max);
}
