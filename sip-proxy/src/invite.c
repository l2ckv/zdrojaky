#include <stdio.h>
#include <windows.h>
#include "declarations.h"

void process_invitation_request(struct sockaddr_in client, const char *buffer, int transaction_id)
{
    char caller_ext[10], invited_user[10], call_id[80];
    REGISTERED_CLIENT reg_client;

    /* find caller extension, call id and invited user's extension */
    strcpy(caller_ext, get_extension_from_message(buffer, "Contact:"));
    strcpy(call_id, get_call_id_from_message(buffer));
    strcpy(invited_user, get_extension_from_message(buffer, "INVITE"));

    /* create a new call in database */
    create_new_call(caller_ext, invited_user, call_id);

    /* find the invited user in location table */
    if (!find_registered_client(invited_user, &reg_client))
    {
        not_found(client, buffer, transaction_id);
        update_call_state(call_id, "failed");
        return;
    }

    /* invite the found client to a call and create a new call */
    invite_other_client(buffer, caller_ext, reg_client, transaction_id);
}

void invite_other_client(const char *buffer, char *caller_ext, REGISTERED_CLIENT other_client, int transaction_id)
{
    char *line_ptr, client_ip[16];
    char response[1500], tmp_str[500];
    int max_forw, client_port, res_len = 0;
    strcpy(client_ip, inet_ntoa(other_client.ipInfo.sin_addr));
    client_port = ntohs(other_client.ipInfo.sin_port);
    sprintf(tmp_str, "INVITE sip:%s@%s:%d SIP/2.0\r\n",
            other_client.extension, client_ip, client_port);
    append_to_string(response, tmp_str, &res_len);
    line_ptr = my_strtok(buffer, "\r\n"); // skip first line
    for (line_ptr = my_strtok(NULL, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "Route:") || string_begins(line_ptr, "Supported:") ||
            string_begins(line_ptr, "User-Agent:"))
        {
            continue; // delete the field
        }
        else if (string_begins(line_ptr, "Max-Forwards:"))
        {
            sscanf(line_ptr, "Max-Forwards: %d", &max_forw);
            sprintf(tmp_str, "Max-Forwards: %d\r\n", max_forw-1);
            append_to_string(response, tmp_str, &res_len);
            sprintf(tmp_str, "Record-Route: <sip:%s;lr>\r\n", cfg.ip_address);
            append_to_string(response, tmp_str, &res_len);
        }
        else if (string_begins(line_ptr, "Via:"))
        {
            strcpy(tmp_str, get_server_via());
            append_to_string(response, tmp_str, &res_len);
            goto keep_header_as_is;
        }
        else if (string_begins(line_ptr, "Allow:"))
        {
            sprintf(tmp_str, "Allow: INVITE, ACK, CANCEL, BYE\r\n");
            append_to_string(response, tmp_str, &res_len);
        }
        else if (string_begins(line_ptr, "Content-Length:"))
        {
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
    send_datagram(response, &(other_client.ipInfo), res_len);
    archive_sip_message(response, "PS", other_client.extension, transaction_id);
}
