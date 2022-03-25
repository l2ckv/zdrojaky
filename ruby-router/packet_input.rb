
def open_interfaces(int_names)
  routing_table = Hash.new
  int_names.each do |dev_name|
    tmp_pcap = FFI::Pcap::Live.new(:dev => dev_name, :snaplen => 65536,
                                   :promisc => true, :timeout => 0)
    tmp_pcap.non_blocking = true
    tmp_pcap.direction = 'in'
    network = tmp_pcap.network.to_s
    mask = tmp_pcap.netmask.to_s
    prefix_len = mask.to_prefix_len
    network_with_mask = "#{network}/#{prefix_len}"
    ip_network = IPAddr.new(network_with_mask)
    $pcap_hash[ip_network] = tmp_pcap
    stats_in = ProtocolStats.new(0, 0, 0)
    stats_out = ProtocolStats.new(0, 0, 0)
    $stats_hash[tmp_pcap] = StatsEntry.new(stats_in, stats_out)
    tmp_entry = RoutingEntry.new('self', dev_name, 'direct')
    routing_table[ip_network] = tmp_entry
  end
  routing_table
end

def next_frame
  $pcap_hash.each do |ip_network, interface|
    pcap_packet = interface.next
    if pcap_packet
      frame = pcap_packet.body
      return frame, ip_network
    end
  end
  return nil, nil
end

$update_socket_out = UDPSocket.new
$update_socket_out.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)

def send_on_all_interfaces(ip_data)
  $pcap_hash.values.each do |interface|
    dst_ip = interface.broadcast_address
    $update_socket_out.send ip_data, 0, dst_ip, 4000
  end
end
