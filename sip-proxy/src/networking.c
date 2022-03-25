#include <windows.h>
#include "networking.h"

SOCKET serverSocket;

void start_listening(const char *server_ip)
{
    WSADATA wsaData;
    unsigned long on = 1;
    SOCKADDR_IN serverInfo;
    WSAStartup(MAKEWORD(2, 0), &wsaData);
    serverSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    memset(&serverInfo, 0, sizeof(serverInfo));
    serverInfo.sin_family = AF_INET;
    serverInfo.sin_addr.s_addr = inet_addr(server_ip);
    serverInfo.sin_port = htons(5060);
    bind(serverSocket, (LPSOCKADDR)&serverInfo, sizeof(struct sockaddr));
    ioctlsocket(serverSocket, FIONBIO, &on);
}

int receive_datagram(char *buffer, struct sockaddr_in *client, int max_len)
{
    int clientStructSize = sizeof(*client);
    return recvfrom(serverSocket, buffer,
                    max_len, 0,
                    (struct sockaddr *)client,
                    &clientStructSize);
}

void send_datagram(char *buffer, struct sockaddr_in *client, int buf_len)
{
    sendto(serverSocket, buffer, buf_len, 0, (struct sockaddr *)client, sizeof(*client));
}

void deinit_networking()
{
    closesocket(serverSocket);
    WSACleanup();
}
