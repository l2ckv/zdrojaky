#include <stdio.h>
#include <stdlib.h>
#include "misc.h"

int string_begins(const char *str, const char *pre)
{
    while (*pre != 0)
    {
        if (*str == *pre)
        {
            str++;
            pre++;
        }
        else
        {
            return 0;
        }
    }
    return 1;
}

char *get_string_between_chars(const char *src, char c1, char c2, int incl_c2)
{
    static char result[1024];
    int copying, i = 0;
    for (copying = 0; *src != 0; src++)
    {
        if (copying)
        {
            if (*src == c2)
            {
                if (incl_c2) result[i++] = *src;
                result[i] = '\0';
                return result;
            }
            result[i++] = *src;
        }
        else
        {
            if (*src == c1) copying = 1;
        }
    }
    // if end character is not found, string is copied till the end
    return result;
}

char *my_strtok(const char *str, const char *delimiters)
{
    static char s_str[2048];
    if (str == NULL)
    {
        return strtok(NULL, delimiters);
    }
    else
    {
        strcpy(s_str, str);
        return strtok(s_str, delimiters);
    }
}

char *get_extension_from_line(const char *line_ptr)
{
    static char extension[10];
    char tmp[100];
    strcpy(tmp, get_string_between_chars(line_ptr, 's', '@', 1));
    strcpy(extension, get_string_between_chars(tmp, ':', '@', 0));
    return extension;
}

char *get_extension_from_message(const char *buffer, const char *line_begin)
{
    static char from_ext[10];
    char *line_ptr;
    line_ptr = get_line_which_begins(buffer, line_begin);
    strcpy(from_ext, get_extension_from_line(line_ptr));
    return from_ext;
}

char *get_call_id_from_message(const char *buffer)
{
    static char call_id[100];
    char *line_ptr;
    line_ptr = get_line_which_begins(buffer, "Call-ID");
    sscanf(line_ptr, "Call-ID: %s", call_id);
    return call_id;
}

char *get_first_line(const char *buffer)
{
    static char first_line[80];
    int i;
    for (i = 0; buffer[i] != '\r'; i++)
        first_line[i] = buffer[i];
    first_line[i] = '\0';
    return first_line;
}

char *get_line_which_begins(const char *buffer, const char *pre)
{
    static char line[200];
    char *line_ptr, buffer2[1500];
    strcpy(buffer2, buffer);
    for (line_ptr = strtok(buffer2, "\r\n"); line_ptr != NULL; line_ptr = strtok(NULL, "\r\n"))
    {
        if (!string_begins(line_ptr, pre))
            continue;
        strcpy(line, line_ptr);
        return line;
    }
    return NULL;
}

char *get_cseq_from_message(const char *buffer)
{
    static char cseq[40];
    char *line_ptr;
    line_ptr = get_line_which_begins(buffer, "CSeq");
    strcpy(cseq, get_string_between_chars(line_ptr, ' ', '\r', 0));
    return cseq;
}

int get_cseq_as_integer(const char *buffer)
{
    return atoi(get_cseq_from_message(buffer));
}

void append_to_string(char *dst, const char *src, int *dst_len)
{
    strcpy(dst+*dst_len, src);
    *dst_len += strlen(src);
}
