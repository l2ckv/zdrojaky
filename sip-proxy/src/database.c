#include <windows.h>
#include <mysql.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "declarations.h"

CHALLENGE open_challenges[MAX_CHALLENGES];
int cur_challenge_index = 0;

MYSQL *conn;

void connect_to_database()
{
   conn = mysql_init(NULL);
   if (!mysql_real_connect(conn, cfg.sql_server_ip,
        cfg.sql_user, cfg.sql_pass, cfg.sql_db_name,
        cfg.sql_port, NULL, 0))
    {
        printf("%s\n", mysql_error(conn));
        exit(1);
    }
    printf("Connected to MySQL database.\n\n");
}

int does_user_exist(char *username)
{
    if (get_HA1_for_user(username) == NULL)
        return 0;
    else
        return 1;
}

char *create_challenge_for_user(const char *username, const char *server_ip)
{
    char *nonce = get_random_string(20);
    char HA2[33], sip_uri[30];
    char input2[100], input3[100];
    char *HA1, *tmp_ptr;
    HA1 = get_HA1_for_user(username);
    sprintf(sip_uri, "sip:%s", server_ip);
    sprintf(input2, "REGISTER:%s", sip_uri);
    tmp_ptr = get_md5_hash(input2);
    strcpy(HA2, tmp_ptr);
    sprintf(input3, "%s:%s:%s", HA1, nonce, HA2);
    tmp_ptr = get_md5_hash(input3);
    strcpy(open_challenges[cur_challenge_index].response, tmp_ptr);
    cur_challenge_index = (cur_challenge_index + 1)%MAX_CHALLENGES;
    return nonce;
}

int is_response_valid(char *response)
{
    int i;
    for (i = 0; i < MAX_CHALLENGES; i++)
    {
        if (!strcmp(open_challenges[i].response, response))
        {
            memset(open_challenges[i].response, '\0', 33);
            return 1;
        }
    }
    return 0;
}

void register_user_on_server(const char *username, char *user_ip, int port, int timeout)
{
    char sql_query[300];
    sprintf(sql_query, "insert into registered_users(extension, IP_Address,"
                       "port, registered_ts, expiration_ts) values(\"%s\","
                       "\"%s\",%d,now(),now()+interval %d second) on duplicate "
                       "key update registered_ts=now(), expiration_ts=now()+"
                       "interval %d second", username, user_ip, port, timeout,
                       timeout);
    execute_sql_query(sql_query);
}

void deregister_user_from_server(const char *username)
{
    char sql_query[100];
    sprintf(sql_query, "delete from registered_users where extension=%s", username);
    execute_sql_query(sql_query);
}

void delete_old_registrations()
{
    execute_sql_query("delete from registered_users where expiration_ts < now()");
}

char *get_HA1_for_user(const char *username)
{
    static char HA1[33];
    char sql_query[100];
    MYSQL_RES *res;
    MYSQL_ROW row;
    sprintf(sql_query, "select HA1 from user_accounts where extension=%s", username);
    execute_sql_query(sql_query);
    res = mysql_use_result(conn);
    row = mysql_fetch_row(res);
    if (row != NULL) strcpy(HA1, row[0]);
    mysql_free_result(res);
    return HA1;
}

int find_registered_client(const char *extension, REGISTERED_CLIENT *result)
{
    struct sockaddr_in dst;
    char sql_query[100];
    MYSQL_RES *res;
    MYSQL_ROW row;
    sprintf(sql_query, "select IP_address,port from registered_users "
                       "where extension=%s", extension);
    execute_sql_query(sql_query);
    res = mysql_use_result(conn);
    row = mysql_fetch_row(res);
    if (row == NULL)
    {
        mysql_free_result(res);
        return 0;
    }
    else
    {
        memset(&dst, 0, sizeof(dst));
        dst.sin_family = AF_INET;
        dst.sin_addr.s_addr = inet_addr(row[0]);
        dst.sin_port = htons(atoi(row[1]));
        memcpy(&result->ipInfo, &dst, sizeof(dst));
        strcpy(result->extension, extension);
        mysql_free_result(res);
        return 1;
    }
}

char *find_extension_by_location(struct sockaddr_in client)
{
    static char ext[10];
    char sql_query[200];
    MYSQL_RES *res;
    MYSQL_ROW row;
    sprintf(sql_query, "select extension from registered_users where "
                       "IP_address=\"%s\" and port=%d", inet_ntoa(client.sin_addr),
                        ntohs(client.sin_port));
    execute_sql_query(sql_query);
    res = mysql_use_result(conn);
    row = mysql_fetch_row(res);
    if (row == NULL)
    {
        printf("*** ERROR: cannot find extension by location\n");
        exit(1);
    }
    else
    {
        strcpy(ext, row[0]);
        mysql_free_result(res);
    }
    return ext;
}

int execute_sql_query(const char *sql_query)
{
    if (mysql_query(conn, sql_query))
    {
        printf("%s\n%s\n", sql_query, mysql_error(conn));
        return 0;
    }
    return 1;
}

void create_new_call(const char *from_ext, const char *to_ext, const char *call_id)
{
    char sql_query[500];
    sprintf(sql_query, "insert into sip_calls values (\"%s\",\"%s\",now(),null,"
                       "null,null,\"dialed\",\"%s\")", from_ext, to_ext, call_id);
    execute_sql_query(sql_query);
    printf("created new call, call_id = %s\n", call_id);
}

void update_call_state(const char *call_id, const char *new_state)
{
    char sql_query[500], ts_name[20];
    if (!strcmp(new_state, "cancelled") ||
        !strcmp(new_state, "declined") ||
        !strcmp(new_state, "failed"))
        strcpy(ts_name, "ended_ts");
    else
        sprintf(ts_name, "%s_ts", new_state);
    sprintf(sql_query, "update sip_calls set state=\"%s\",%s=now() where "
                       "call_id=\"%s\"", new_state, ts_name, call_id);
    execute_sql_query(sql_query);
}

int has_call_been_answered(const char *call_id)
{
    char sql_query[100];
    MYSQL_RES *res;
    MYSQL_ROW row;
    sprintf(sql_query, "select * from sip_calls where call_id=\"%s\" "
                       "and answered_ts is not null", call_id);
    execute_sql_query(sql_query);
    res = mysql_use_result(conn);
    row = mysql_fetch_row(res);
    if (row == NULL)
    {
        mysql_free_result(res);
        return 0;
    }
    else
    {
        mysql_free_result(res);
        return 1;
    }
}

int create_new_transaction(const char *src, int cseq_num, const char *call_id)
{
    char sql_query[500];
    int transaction_id;
    sprintf(sql_query, "insert into sip_transactions(src,cseq_num,call_id) values"
                       "(\"%s\",\"%d\",\"%s\")", src, cseq_num, call_id);
    execute_sql_query(sql_query);
    transaction_id =  mysql_insert_id(conn);
    printf("created new transaction, id = %d\n", transaction_id);
    return transaction_id;
}

int create_new_transaction_from_message(const char *buffer)
{
    char src[10], call_id[80], from_line[100];
    int cseq_num;
    strcpy(from_line, get_line_which_begins(buffer, "From"));
    strcpy(src, get_extension_from_line(from_line));
    strcpy(call_id, get_call_id_from_message(buffer));
    cseq_num = get_cseq_as_integer(buffer);
    return create_new_transaction(src, cseq_num, call_id);
}

int find_sip_transaction_from_message(const char *buffer)
{
    char src[10], call_id[80];
    int cseq_num;
    find_transaction_info_from_message(buffer, src, &cseq_num, call_id);
    return find_sip_transaction(src, cseq_num, call_id);
}

void find_transaction_info_from_message(const char *buffer, char *src, int *cseq_num, char *call_id)
{
    char from_line[100];
    strcpy(from_line, get_line_which_begins(buffer, "From"));
    strcpy(src, get_extension_from_line(from_line));
    strcpy(call_id, get_call_id_from_message(buffer));
    *cseq_num = get_cseq_as_integer(buffer);
}

int find_sip_transaction(const char *src, int cseq_num, const char *call_id)
{
    char sql_query[500];
    MYSQL_RES *res;
    MYSQL_ROW row;
    int transaction_id;
    sprintf(sql_query, "select transaction_id from sip_transactions where "
                       "src=\"%s\" and cseq_num=%d and call_id=\"%s\"", src,
                       cseq_num, call_id);
    execute_sql_query(sql_query);
    res = mysql_use_result(conn);
    row = mysql_fetch_row(res);
    if (row == NULL)
    {
        printf("*** ERROR: cannot find transaction\n");
        exit(1);
    }
    else
    {
        transaction_id = atoi(row[0]);
        mysql_free_result(res);
        return transaction_id;
    }
}

void archive_sip_message(const char *buffer, const char *src, const char *dst, int transaction_id)
{
    char sql_query[2000];
    char *first_line, *call_id;
    first_line = get_first_line(buffer);
    call_id = get_call_id_from_message(buffer);
    sprintf(sql_query, "insert into sip_messages values(\"%s\",\"%s\",\"%s\""
                       ",now(),\"%d\",\"%s\",\"%s\")", src, dst, first_line,
                       transaction_id, call_id, buffer);
    execute_sql_query(sql_query);
}

void deinit_database()
{
    mysql_close(conn);
}
