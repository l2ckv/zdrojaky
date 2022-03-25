#ifndef NETWORKING_H
#define NETWORKING_H

#include <windows.h>

void start_listening(const char *server_ip);
int receive_datagram(char *buffer, struct sockaddr_in *client, int max_len);
void send_datagram(char *buffer, struct sockaddr_in *client, int buf_len);
void deinit_networking();

#endif // NETWORKING_H
