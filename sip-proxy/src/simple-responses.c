#include <stdio.h>
#include <windows.h>
#include "declarations.h"

void not_implemented(struct sockaddr_in client, const char *buffer)
{
    simple_response(client, buffer, "SIP/2.0 501 Not Implemented\r\n", -1);
}

void not_found(struct sockaddr_in client, const char *buffer, int transaction_id)
{
    simple_response(client, buffer, "SIP/2.0 404 Not Found\r\n", transaction_id);
}

void simple_response(struct sockaddr_in client, const char *buffer, const char *reply, int transaction_id)
{
    char *line_ptr;
    char response[1500];
    int res_len = 0;
    strcpy(response, reply);
    res_len = strlen(response);
    line_ptr = my_strtok(buffer, "\r\n"); // skip first line
    for (line_ptr = my_strtok(NULL, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "Route:") || string_begins(line_ptr, "Max-Forwards:"))
        {
            continue;
        }
        else if (string_begins(line_ptr, "Content-Length"))
        {
            append_to_string(response, "Content-Length: 0\r\n\r\n", &res_len);
            break;
        }
        else
        {
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, "\r\n", &res_len);
        }
    }
    append_to_string(response, "\r\n", &res_len);
    send_datagram(response, &client, res_len);
    if (transaction_id != -1)
    {
        char msg_src[10];
        strcpy(msg_src, find_extension_by_location(client));
        archive_sip_message(response, "PS", msg_src, transaction_id);
    }
}
