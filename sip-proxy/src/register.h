#ifndef REGISTRATION_H
#define REGISTRATION_H

typedef enum
{
    REGISTRATION_CHALLENGE,
    REGISTRATION_OK,
    REGISTRATION_NOT_FOUND,
    REGISTRATION_FORBIDDEN
} REG_RESPONSE_TYPE;

void process_registration_request(struct sockaddr_in client, const char *buffer);
void deregister_client(struct sockaddr_in client, const char *buffer);
void send_registration_packet(struct sockaddr_in client, const char *buffer,
                              REG_RESPONSE_TYPE type, const char *extension);
char *reg_response_type_to_string(REG_RESPONSE_TYPE type);

#endif // REGISTRATION_H
