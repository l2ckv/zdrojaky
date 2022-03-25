#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config-file.h"

void load_server_config(const char *file)
{
    char line_buf[1000], field[20], value[50];
    FILE *fp = fopen(file, "rt");
    if (fp == NULL)
    {
        printf("Unable to open config file %s\n", file);
        exit(1);
    }
    for (;;)
    {
        fgets(line_buf, 1000, fp);
        if (feof(fp)) break;
        if (line_buf[0] == '#') continue;
        if (strlen(line_buf) < 2) continue;
        sscanf(line_buf, "%s\t%s\n", field, value);
        if (!strcmp(field, "SERVER_IP"))
        {
            printf("SERVER_IP = %s\n", value);
            strcpy(cfg.ip_address, value);
        }
        else if (!strcmp(field, "REG_TIMEOUT"))
        {
            int timeout = atoi(value);
            printf("REG_TIMEOUT = %d seconds\n", timeout);
            cfg.reg_timeout = timeout;
        }
        else if (!strcmp(field, "SQL_SERVER_IP"))
        {
            printf("SQL_SERVER_IP = %s\n", value);
            strcpy(cfg.sql_server_ip, value);
        }
        else if (!strcmp(field, "SQL_PORT"))
        {
            int port = atoi(value);
            printf("SQL_PORT = %d\n", port);
            cfg.sql_port = port;
        }
        else if (!strcmp(field, "SQL_USER"))
        {
            printf("SQL_USER = %s\n", value);
            strcpy(cfg.sql_user, value);
        }
        else if (!strcmp(field, "SQL_PASS"))
        {
            printf("SQL_PASS = ********\n");
            strcpy(cfg.sql_pass, value);
        }
        else if (!strcmp(field, "SQL_DB_NAME"))
        {
            printf("SQL_DB_NAME = %s\n", value);
            strcpy(cfg.sql_db_name, value);
        }
        else
        {
            printf("warning: unknown field %s\n", field);
        }
    }
    fclose(fp);
}
