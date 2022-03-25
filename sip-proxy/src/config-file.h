#ifndef CONFIG_FILE_H
#define CONFIG_FILE_H

typedef struct server_config
{
    char ip_address[16];
    int reg_timeout; // in seconds
    char sql_server_ip[16];
    int sql_port;
    char sql_user[20];
    char sql_pass[30];
    char sql_db_name[20];
} SERVER_CONFIG;

void load_server_config(const char *file);

SERVER_CONFIG cfg;

#endif // CONFIG_FILE_H
