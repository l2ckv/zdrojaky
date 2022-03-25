

def get_routing_table(as_update = false)
  table_str = String.new
  networks = $routing_table.sorted_networks
  networks.each_with_index do |ip_network, id|
    routing_entry = $routing_table[ip_network]
    table_str += "#{ip_network}/#{ip_network.cidr}"
    unless as_update
      table_str += " #{routing_entry.gateway} " +
                   "#{routing_entry.interface} " +
                   "#{routing_entry.type} #{id}"
    end
    table_str += "\n"
  end
  if as_update
    table_str += "valid_time 3"
  end
  table_str
end

def find_interface_by_ip(ip_address)
  dev_name = nil
  $pcap_hash.each do |ip_network, pcap|
    if ip_network.include?(ip_address)
      dev_name = pcap.device; break
    end
  end
  dev_name
end
