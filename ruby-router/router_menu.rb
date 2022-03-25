require 'socket'
require 'timeout'

class String
  def any_if_empty
    self.length == 0 ? 'any' : self
  end
end

def array_to_menu(title, array)
  print "#{title}:\n\n"
  array.each_with_index do |value, index|
    readable_form = value.capitalize.gsub('_', ' ')
    puts "  (#{index+1}) #{readable_form}"
  end
end

print 'Checking if router is running...'
$reply_socket = UDPSocket.new
$reply_socket.bind("127.0.0.1", 2000)

def send_message(msg)
  UDPSocket.new.send msg, 0, "127.0.0.1", 3000
end

def wait_for_reply
  begin
    timeout(2) do
      reply, addr = $reply_socket.recvfrom(1500)
      return reply
    end
  rescue Timeout::Error
    puts "timed out"; exit
  end
end

send_message 'running?'
reply = wait_for_reply
print "#{reply}\n\n"
router_name = reply.split(' ')[-1]

def display_the_routing_table
  send_message 'send_me_the_routing_table'
  routing_entries = wait_for_reply.split("\n")
  print "\n#{'Network'.center(19)}|#{'Gateway'.center(19)}|"
  print "#{'Int.'.center(8)}|#{'Type'.center(11)}| ID\n#{'-'*64}\n"
  routing_entries.each do |entry|
    tokens = entry.split(' ')
    network = tokens[0].center(19)
    gateway = tokens[1].center(19)
    interface = tokens[2].center(8)
    type = tokens[3..-2].join(' ').center(11)
    id = tokens[-1].center(3)
    puts "#{network}|#{gateway}|#{interface}|#{type}|#{id}"
  end
  puts
end

def send_static_route(dst, prefix_len, next_hop)
  send_message "new_static_route #{dst}/#{prefix_len} via #{next_hop}"
end

def add_a_static_route
  print "Network: "; network = gets.chomp
  tokens = network.split('/')
  dst = tokens[0]
  prefix_len = tokens[1]
  print "Next hop: "; next_hop = gets.chomp
  send_static_route(dst, prefix_len, next_hop)
end

def delete_static_route
  print "ID: "; id = gets.chomp
  send_message "delete_static_route #{id}"
end

def display_existing_rules
  send_message 'send_me_all_rules'
  rules = wait_for_reply.split("\n")
  print "\n#{'src IP address'.center(16)}|"
  print "#{'dst IP address'.center(16)}|"
  print "#{'protocol'.center(10)}|#{'src ports'.center(12)}|"
  print "#{'dst ports'.center(12)}| ID\n#{'-'*74}\n"
  rules.each do |rule|
    tokens = rule.split(' ')
    src_ip = tokens[0].center(16)
    dst_ip = tokens[1].center(16)
    protocol = tokens[2].center(10)
    src_ports = tokens[3].center(12)
    dst_ports = tokens[4].center(12)
    id = tokens[5].center(3)
    puts "#{src_ip}|#{dst_ip}|#{protocol}|#{src_ports}|#{dst_ports}|#{id}"
  end
  puts
end

def add_new_rule
  print "Source IP address (ENTER for any): "
  src_ip =  gets.chomp.any_if_empty
  print "Destination IP address (ENTER for any): "
  dst_ip = gets.chomp.any_if_empty
  print "Protocol (UDP, TCP, ICMP, ENTER for any): "
  protocol = gets.chomp.any_if_empty.downcase
  msg = "add_new_rule #{src_ip} #{dst_ip} #{protocol}"
  if protocol == 'icmp'
    msg += " n/a n/a"
  else
    print "Source port(s): "
    src_ports = gets.chomp.any_if_empty
    print "Destination port(s): "
    dst_ports = gets.chomp.any_if_empty
    msg += " #{src_ports} #{dst_ports}"
  end
  send_message msg
end

def delete_existing_rule
  print "ID: "; id = gets.chomp
  send_message "delete_rule #{id}"
end

def display_statistics
  send_message "send_me_all_stats"
  puts "\n#{wait_for_reply}"
end

def reset_statistics
  send_message "reset_stats"
end

router_menu = [
  'display_the_routing_table',
  'add_a_static_route',
  'delete_a_static_route',
  'display_existing_rules',
  'add_a_new_rule',
  'delete_an_existing_rule',
  'display_statistics',
  'reset_all_statistics' ]

array_to_menu("Main menu", router_menu)

print "\n#{router_name} > "
choice = gets.chomp.to_i

case choice
  when 1 then display_the_routing_table
  when 2 then add_a_static_route
  when 3 then delete_static_route
  when 4 then display_existing_rules
  when 5 then add_new_rule
  when 6 then delete_existing_rule
  when 7 then display_statistics
  when 8 then reset_statistics
end
