$send_socket = UDPSocket.new
$recv_socket = UDPSocket.new

def start_listening_on_loopback
  $recv_socket.bind('127.0.0.1', 3000)
end

def send_reply(reply)
  $send_socket.send reply, 0, '127.0.0.1', 2000
end

def send_routing_table
  reply = get_routing_table
  send_reply reply
end

def add_static_route(payload)
  puts "new static route: #{payload}"
  tokens = payload.split(' ')
  network_with_mask = tokens[0]
  gateway = tokens[2]
  puts "#{network_with_mask} via #{gateway}"
  new_network = IPAddr.new(network_with_mask)
  dev_name = find_interface_by_ip(gateway)
  dev_name = '?' unless dev_name
  tmp_entry = RoutingEntry.new(gateway, dev_name, 'static')
  $routing_table[new_network] = tmp_entry
end

def delete_static_route(payload)
  network = $routing_table.sorted_networks[payload.to_i]
  $routing_table.delete(network)
end

def add_new_rule(payload)
  tokens = payload.split(' ')
  src_ip = tokens[0]
  dst_ip = tokens[1]
  protocol = tokens[2]
  src_ports = tokens[3]
  dst_ports = tokens[4]
  $filters << FilterEntry.new(src_ip, dst_ip, protocol,
                              src_ports, dst_ports)
end

def send_all_rules
  reply = String.new
  $filters.each_with_index do |rule, id|
    reply += "#{rule.src_ip} #{rule.dst_ip} #{rule.protocol} "
    reply += "#{rule.src_ports} #{rule.dst_ports} #{id}\n"
  end
  send_reply reply
end

def delete_rule(payload)
  $filters.delete_at(payload.to_i)
end

def stats_for_protocol_entry(ps)
  # ps = protocol stats
  tmp_str = String.new
  tmp_str += "#{ps.tcp.to_s.rjust(3)} TCP, "
  tmp_str += "#{ps.udp.to_s.rjust(3)} UDP, "
  tmp_str += "#{ps.icmp.to_s.rjust(3)} ICMP "
  tmp_str + "packets\n"
end

def send_all_stats
  reply = String.new
  $stats_hash.each do |pl, se|
    # pl = pcap_live, se = stats entry
    reply += "interface #{pl.device} (#{pl.ip_address})\n"
    reply += "Input:\t"
    reply += stats_for_protocol_entry(se.input)
    reply += "Output:\t"
    reply += stats_for_protocol_entry(se.output) + "\n"
  end
  send_reply reply
end

def zero_protocol_entry(ps)
  # ps = protocol stats
  ps.tcp = 0
  ps.udp = 0
  ps.icmp = 0
end

def reset_all_stats
  $stats_hash.values.each do |se|
    # se = stats entry
    zero_protocol_entry(se.input)
    zero_protocol_entry(se.output)
  end
end

def process_message(msg)
  first_space = msg.index(' ')
  first_word = first_space ? msg[0...first_space] : msg
  payload = first_space ? msg[first_space+1..-1] : msg
  case first_word
    when 'running?' then send_reply "yes, name = #{$router_name}"
    when 'send_me_the_routing_table' then send_routing_table
    when 'new_static_route' then add_static_route(payload)
    when 'delete_static_route' then delete_static_route(payload)
    when 'send_me_all_rules' then send_all_rules
    when 'add_new_rule' then add_new_rule(payload)
    when 'delete_rule' then delete_rule(payload)
    when 'send_me_all_stats' then send_all_stats
    when 'reset_stats' then reset_all_stats
  end
end

def check_for_message
  begin
    process_message $recv_socket.recvfrom_nonblock(1500)[0]
  rescue Errno::EWOULDBLOCK
    # no command received
  end
end
