require './requirements'

RoutingEntry = Struct.new(:gateway, :interface, :type,
                          :received, :valid_time)
FilterEntry = Struct.new(:src_ip, :dst_ip, :protocol,
                         :src_ports, :dst_ports)
StatsEntry = Struct.new(:input, :output)
ProtocolStats = Struct.new(:tcp, :udp, :icmp)

$pcap_hash = Hash.new
$stats_hash = Hash.new

$router_name, int_names = load_config_file('router.cfg')
start_listening_on_loopback
$routing_table = open_interfaces(int_names)

class IPAddr
  attr_reader :mask_addr
  def cidr
    (0..31).to_a.inject(0) { |bits, i| bits + ((mask_addr & (2**i)) >> i) }
  end
end

class Hash
  # longest prefix match
  def sorted_networks
    self.keys.sort_by { |ip_network| -ip_network.cidr }
  end
end

def route_packet(eth_header, ip_packet, src_ip_network)
  src_ip = ip_packet[12..15].as_ipv4
  dst_ip = ip_packet[16..19].as_ipv4
  l4_protocol = ip_packet[9].as_l4_protocol
  return if l4_protocol == 'unknown'
  ip_data = ip_packet[20..-1]
  if src_ip_network.include?(dst_ip)
    # build MAC table only from local network
    learn_mac_addresses(eth_header, ip_packet)
    if ip_packet.include?('here_is_my_routing_table')
      update_routing_table(ip_data[8..-1], src_ip)
    end
    return # packet is from LAN, don't route it
  end
  update_stats(src_ip_network, l4_protocol, 'in')
  return if should_be_filtered? l4_protocol, src_ip, dst_ip, ip_data
  gateway = nil; int_out = nil
  $routing_table.sorted_networks.each do |ip_network|
    routing_entry = $routing_table[ip_network]
    if ip_network.include?(dst_ip)
      gateway = routing_entry.gateway
      int_out = $pcap_hash.values.find { |pcap_handle|
        pcap_handle.device == routing_entry.interface
      }
      break
    end
  end
  return unless gateway
  add_packet_to_output_queue ip_packet, gateway, int_out
  update_stats(src_ip_network, l4_protocol, 'out')
end

def update_stats(src_ip_network, l4_protocol, direction)
  tmp_pcap = $pcap_hash[src_ip_network]
  if direction == 'in'
    work_entry = $stats_hash[tmp_pcap].input
  else
    work_entry = $stats_hash[tmp_pcap].output
  end
  case l4_protocol
    when 'tcp' then work_entry.tcp += 1
    when 'udp' then work_entry.udp += 1
    when 'icmp' then work_entry.icmp += 1
  end
end

while true do
  check_for_message
  send_updates
  check_routing_table
  eth_frame, src_ip_network = next_frame
  next unless eth_frame
  eth_header = eth_frame[0..13]
  ip_packet = eth_frame[14..-1]
  next unless eth_header[12..13].as_ethertype == 'IPv4'
  route_packet(eth_header, ip_packet, src_ip_network) 
end
