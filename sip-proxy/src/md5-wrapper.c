#include <stdio.h>
#include <string.h>
#include "md5-wrapper.h"
#include "md5.h"

char *get_md5_hash(char *input)
{
    static char md5String[33];
    unsigned char md5Result[16];
    int i;
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, input, strlen(input));
    MD5_Final(md5Result, &ctx);
    for (i = 0; i < 16; i++)
        sprintf(&md5String[i*2], "%02x", (unsigned int)md5Result[i]);
    return md5String;
}
