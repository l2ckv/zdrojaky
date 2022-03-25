#include <stdio.h>
#include <windows.h>
#include "declarations.h"

int is_message_a_request(const char *buffer);
int is_message_a_status(const char *buffer);
void process_request(struct sockaddr_in client, const char *buffer);
void process_status(struct sockaddr_in client, const char *buffer);

int main()
{
    char buffer[1500];
    struct sockaddr_in client;
    load_server_config("sip-server.conf");
    init_random_generator();
    start_listening(cfg.ip_address);
    connect_to_database();
    memset(buffer, 0, 1500);
    for (;;)
    {
        if (receive_datagram(buffer, &client, 1500) != -1)
        {
            if (strlen(buffer) <= 3)
                continue; // linphone
            else if (string_begins(buffer, "exit"))
                break;
            else if (is_message_a_request(buffer))
                process_request(client, buffer);
            else if (is_message_a_status(buffer))
                process_status(client, buffer);
            memset(buffer, 0, 1500);
        }
    }
    printf("SIP proxy exiting.\n");
    deinit_database();
    deinit_networking();
    return 0;
}

int is_message_a_request(const char *buffer)
{
    if (string_begins(buffer, "REGISTER") || string_begins(buffer, "INVITE") ||
        string_begins(buffer, "ACK") || string_begins(buffer, "BYE") ||
        string_begins(buffer, "OPTIONS") || string_begins(buffer, "CANCEL"))
        return 1;
    else
        return 0;
}

int is_message_a_status(const char *buffer)
{
    if (string_begins(buffer, "SIP/2.0 180 Ringing") ||
        string_begins(buffer, "SIP/2.0 200 OK") ||
        string_begins(buffer, "SIP/2.0 100 Trying") ||
        string_begins(buffer, "SIP/2.0 487 Request Terminated") ||
        string_begins(buffer, "SIP/2.0 487 Request Cancelled") ||
        string_begins(buffer, "SIP/2.0 603 Decline"))
        return 1;
    else
        return 0;
}

void process_request(struct sockaddr_in client, const char *buffer)
{
    char msg_src[10];
    int transaction_id;
    if (string_begins(buffer, "INVITE") || string_begins(buffer, "BYE"))
    {
        strcpy(msg_src, find_extension_by_location(client));
        transaction_id = create_new_transaction_from_message(buffer);
        archive_sip_message(buffer, msg_src, "PS", transaction_id);
        if (string_begins(buffer, "INVITE"))
            process_invitation_request(client, buffer, transaction_id);
        else
            send_request_to_other_side(buffer, transaction_id);
    }
    else if (string_begins(buffer, "CANCEL"))
    {
        strcpy(msg_src, find_extension_by_location(client));
        transaction_id = find_sip_transaction_from_message(buffer);
        archive_sip_message(buffer, msg_src, "PS", transaction_id);
        send_request_to_other_side(buffer, transaction_id);
    }
    else if (string_begins(buffer, "ACK"))
    {
        strcpy(msg_src, find_extension_by_location(client));
        if (has_call_been_answered(get_call_id_from_message(buffer)))
        {
            printf("call has been answered, creating new transaction\n");
            transaction_id = create_new_transaction_from_message(buffer);
        }
        else
        {
            printf("call not answered, searching for an existing transaction\n");
            transaction_id = find_sip_transaction_from_message(buffer);
        }
        archive_sip_message(buffer, msg_src, "PS", transaction_id);
        send_request_to_other_side(buffer, transaction_id);
    }
    else if (string_begins(buffer, "REGISTER"))
    {
        process_registration_request(client, buffer);
    }
    else if (string_begins(buffer, "OPTIONS"))
    {
        not_implemented(client, buffer);
    }
}

void process_status(struct sockaddr_in client, const char *buffer)
{
    char cseq_str[80], msg_src[10];
    int transaction_id;
    transaction_id = find_sip_transaction_from_message(buffer);
    strcpy(msg_src, find_extension_by_location(client));
    archive_sip_message(buffer, msg_src, "PS", transaction_id);
    if (string_begins(buffer, "SIP/2.0 180 Ringing"))
    {
        send_status_to_other_side(buffer);
        update_call_state(get_call_id_from_message(buffer), "ringing");
    }
    else if (string_begins(buffer, "SIP/2.0 200 OK"))
    {
        send_status_to_other_side(buffer);
        strcpy(cseq_str, get_cseq_from_message(buffer));
        if (strstr(buffer, "INVITE"))
            update_call_state(get_call_id_from_message(buffer), "answered");
        else if (strstr(buffer, "BYE"))
            update_call_state(get_call_id_from_message(buffer), "ended");
        else if (strstr(buffer, "CANCEL"))
            update_call_state(get_call_id_from_message(buffer), "cancelled");
        else
            printf("*** unknown method in CSeq of OK\n");
    }
    else if (string_begins(buffer, "SIP/2.0 100 Trying") ||
             string_begins(buffer, "SIP/2.0 487 Request Terminated") ||
             string_begins(buffer, "SIP/2.0 487 Request Cancelled"))
    {
        send_status_to_other_side(buffer);
    }
    else if (string_begins(buffer, "SIP/2.0 603 Decline"))
    {
        send_status_to_other_side(buffer);
        update_call_state(get_call_id_from_message(buffer), "declined");
    }
}
