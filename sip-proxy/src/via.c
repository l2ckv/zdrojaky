#include <stdio.h>
#include "config-file.h"
#include "via.h"

char *get_server_via()
{
    static char server_via[100];
    char branch[60];
    sprintf(branch, "%s%s", VIA_BRANCH_MAGIC_COOKIE, "1234");
    sprintf(server_via, "Via: SIP/2.0/UDP %s:5060;branch=%s\r\n",
                         cfg.ip_address, branch);
    return server_via;
}
