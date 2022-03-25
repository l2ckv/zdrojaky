#include <stdio.h>
#include <windows.h>
#include "declarations.h"

void process_registration_request(struct sockaddr_in client, const char *buffer)
{
    char *line_ptr;
    char extension[10], challenge_response[33];
    int expires, auth_response = 0;
    for (line_ptr = my_strtok(buffer, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "From:"))
        {
            strcpy(extension, get_extension_from_line(line_ptr));
        }
        else if (string_begins(line_ptr, "Authorization:"))
        {
            int i, j;
            for (i = 0; line_ptr[i] != '\0'; i++)
                if (string_begins(line_ptr+i, "response=")) break;
            i += 10; // strlen("response=\"")
            for (j = 0; line_ptr[i] != 34; j++) // 34 = "
                challenge_response[j] = line_ptr[i++];
            auth_response = 1;
        }
        else if (string_begins(line_ptr, "Expires:"))
        {
            sscanf(line_ptr, "Expires: %d", &expires);
        }
    }
    if (does_user_exist(extension) == 0)
        send_registration_packet(client, buffer, REGISTRATION_NOT_FOUND, extension);
    else if (expires == 0)
        deregister_client(client, buffer);
    else if (!auth_response)
        send_registration_packet(client, buffer, REGISTRATION_CHALLENGE, extension);
    else
    {
        if (is_response_valid(challenge_response))
            send_registration_packet(client, buffer, REGISTRATION_OK, extension);
        else
            send_registration_packet(client, buffer, REGISTRATION_FORBIDDEN, extension);
    }
}

void deregister_client(struct sockaddr_in client, const char *buffer)
{
    char *line_ptr;
    char response[1500];
    int res_len = 0;
    printf("deregistering client\n");
    deregister_user_from_server(get_extension_from_line(get_line_which_begins(buffer, "From")));
    strcpy(response, "SIP/2.0 200 OK\r\n");
    res_len = strlen(response);
    line_ptr = my_strtok(buffer, "\r\n"); // skip first line
    for (line_ptr = my_strtok(NULL, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "Contact:") || string_begins(line_ptr, "User-Agent:"))
        {
            continue; // delete the field
        }
        else
        {
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, "\r\n", &res_len);
        }
    }
    append_to_string(response, "\r\n", &res_len);
    send_datagram(response, &client, res_len);
}

void send_registration_packet(struct sockaddr_in client, const char *buffer,
                              REG_RESPONSE_TYPE type, const char *extension)
{
    char *line_ptr, client_ip[16];
    char response[1500], tmp_str[1000];
    int client_port, res_len = 0;
    strcpy(response, reg_response_type_to_string(type));
    res_len = strlen(response);
    line_ptr = my_strtok(buffer, "\r\n");
    for (line_ptr = my_strtok(NULL, "\r\n"); line_ptr != NULL; line_ptr = my_strtok(NULL, "\r\n"))
    {
        if (string_begins(line_ptr, "Route:") || string_begins(line_ptr, "Max-Forwards:") ||
            string_begins(line_ptr, "Expires") || string_begins(line_ptr, "Authorization"))
        {
            continue;
        }
        else if (string_begins(line_ptr, "Contact:"))
        {
            if (type != REGISTRATION_OK) continue;
            sprintf(tmp_str, ";expires=%d\r\n", cfg.reg_timeout);
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, tmp_str, &res_len);
        }
        else if (string_begins(line_ptr, "User-Agent:"))
        {
            if (type == REGISTRATION_CHALLENGE)
            {
                char *nonce = create_challenge_for_user(extension, cfg.ip_address);
                sprintf(tmp_str, "WWW-Authenticate: Digest algorithm=MD5,realm="
                                 "\"%s\",nonce=\"%s\"\r\n", AUTH_REALM, nonce);
                append_to_string(response, tmp_str, &res_len);
            }
        }
        else
        {
            append_to_string(response, line_ptr, &res_len);
            append_to_string(response, "\r\n", &res_len);
        }
    }
    append_to_string(response, "\r\n", &res_len);
    send_datagram(response, &client, res_len);
    if (type == REGISTRATION_OK)
    {
        strcpy(client_ip, inet_ntoa(client.sin_addr));
        client_port = ntohs(client.sin_port);
        register_user_on_server(extension, client_ip, client_port, cfg.reg_timeout);
        printf("registered extension %s at %s:%d\n", extension, client_ip, client_port);
    }
}

char *reg_response_type_to_string(REG_RESPONSE_TYPE type)
{
    static char sip_string[100];
    switch (type)
    {
    case REGISTRATION_CHALLENGE:
        strcpy(sip_string, "SIP/2.0 401 Unauthorized\r\n");
        break;
    case REGISTRATION_OK:
        strcpy(sip_string, "SIP/2.0 200 OK\r\n");
        break;
    case REGISTRATION_NOT_FOUND:
        strcpy(sip_string, "SIP/2.0 404 Not Found\r\n");
        break;
    case REGISTRATION_FORBIDDEN:
        strcpy(sip_string, "SIP/2.0 403 Forbidden (Bad auth)\r\n");
        break;
    default:
        printf("*** ERROR: invalid REG_RESPONSE_TYPE argument\n");
        break;
    }
    return sip_string;
}
