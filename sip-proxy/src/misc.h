#ifndef MISC_H
#define MISC_H

#include <string.h>

int string_begins(const char *str, const char *pre);
char *get_string_between_chars(const char *src, char c1, char c2, int incl_c2);
char *my_strtok(const char *str, const char *delimiters);
char *get_extension_from_line(const char *line_ptr);
char *get_extension_from_message(const char *buffer, const char *line_begin);
char *get_call_id_from_message(const char *buffer);
char *get_first_line(const char *buffer);
char *get_line_which_begins(const char *buffer, const char *pre);
char *get_cseq_from_message(const char *buffer);
int get_cseq_as_integer(const char *buffer);
void append_to_string(char *dst, const char *src, int *dst_len);

#endif // MISC_H
