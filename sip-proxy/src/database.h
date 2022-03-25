#ifndef DATABASE_H
#define DATABASE_H

#include <windows.h>

typedef struct registered_client
{
    struct sockaddr_in ipInfo;
    char extension[10];
} REGISTERED_CLIENT;

typedef struct challenge
{
    char response[33];
} CHALLENGE;

#define MAX_CHALLENGES  20

void connect_to_database();
void deinit_database();
int execute_sql_query(const char *sql_query);

int does_user_exist(char *username);
char *create_challenge_for_user(const char *username, const char *server_ip);
int is_response_valid(char *response);
char *get_HA1_for_user(const char *username);

void register_user_on_server(const char *username, char *user_ip, int port, int timeout);
void deregister_user_from_server(const char *username);
void delete_old_registrations();
int find_registered_client(const char *extension, REGISTERED_CLIENT *result);
char *find_extension_by_location(struct sockaddr_in client);

void create_new_call(const char *from_ext, const char *to_ext, const char *call_id);
void update_call_state(const char *call_id, const char *new_state);
int has_call_been_answered();

int create_new_transaction(const char *src, int cseq_num, const char *call_id);
int create_new_transaction_from_message(const char *buffer);
void find_transaction_info_from_message(const char *buffer, char *src, int *cseq_num, char *call_id);
int find_sip_transaction_from_message(const char *buffer);
int find_sip_transaction(const char *src, int cseq_num, const char *call_id);
void archive_sip_message(const char *buffer, const char *src, const char *dst, int transaction_id);

/*
    It's not a good idea to change this after having created any user
    accounts, since their passwords in the database are stored only as
    hashes relevant to the following string, and so changing it will
    prevent any existing users from logging in.
*/
#define AUTH_REALM  "sip_proxy"

#endif // DATABASE_H
