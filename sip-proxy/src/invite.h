#ifndef INVITE_H
#define INVITE_H

#include "database.h"
#include <windows.h>

void process_invitation_request(struct sockaddr_in client, const char *buffer, int transaction_id);
void invite_other_client(const char *buffer, char *caller_ext, REGISTERED_CLIENT other_client, int transaction_id);

#endif // INVITE_H
