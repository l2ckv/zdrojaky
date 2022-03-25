#include <stdio.h>
#include <windows.h>
#include "declarations.h"

void send_request_to_other_side(const char *buffer, int transaction_id)
{
    char dst_ext[10];
    strcpy(dst_ext, get_extension_from_line(get_first_line(buffer)));
    send_message_to_other_side(buffer, dst_ext, 1, transaction_id);
}

void send_status_to_other_side(const char *buffer)
{
    char dst_ext[10];
    strcpy(dst_ext, get_extension_from_message(buffer, "From"));
    send_message_to_other_side(buffer, dst_ext, 0, -1);
}

void send_message_to_other_side(const char *buffer, const char *dst_ext, int request, int transaction_id)
{
    char *line_ptr;
    char response[1500], tmp_str[200];
    int max_forw, res_len = 0;
    REGISTERED_CLIENT rc;
    if (!find_registered_client(dst_ext, &rc))
        return;
    for (line_ptr = my_strtok(buffer, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "Route"))
        {
            continue;
        }
        else if (string_begins(line_ptr, "Via:"))
        {
            if (request)
            {
                strcpy(tmp_str, get_server_via());
                append_to_string(response, tmp_str, &res_len);
                goto keep_header_as_is;
            }
            else
            {
                line_ptr = my_strtok(NULL, "\r\n");
                goto keep_header_as_is;
            }
        }
        else if (string_begins(line_ptr, "Max-Forwards:"))
        {
            sscanf(line_ptr, "Max-Forwards: %d", &max_forw);
            sprintf(tmp_str, "Max-Forwards: %d\r\n", max_forw-1);
            append_to_string(response, tmp_str, &res_len);
        }
        else if (string_begins(line_ptr, "Content-Length:"))
        {
            // in case of SDP, terminate SIP header
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, "\r\n\r\n", &res_len);
        }
        else
        {
        keep_header_as_is:
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, "\r\n", &res_len);
        }
    }
    append_to_string(response, "\r\n", &res_len);
    send_datagram(response, &(rc.ipInfo), res_len);
    if (transaction_id == -1)
        transaction_id = find_sip_transaction_from_message(buffer);
    archive_sip_message(response, "PS", dst_ext, transaction_id);
}
