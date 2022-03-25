#ifndef SIMPLE_RESPONSES_H
#define SIMPLES_RESPONSES_H

#include <windows.h>

void not_implemented(struct sockaddr_in client, const char *buffer);
void not_found(struct sockaddr_in client, const char *buffer, int transaction_id);
void simple_response(struct sockaddr_in client, const char *buffer, const char *reply, int transaction_id);

#endif // SIMPLE_RESPONSES_H
