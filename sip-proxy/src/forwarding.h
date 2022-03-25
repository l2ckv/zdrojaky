#ifndef FORWARDING_H
#define FORWARDING_H

void send_request_to_other_side(const char *buffer, int transaction_id);
void send_status_to_other_side(const char *buffer);
void send_message_to_other_side(const char *buffer, const char *dst_ext, int request, int transaction_id);

#endif // FORWARDING_H
