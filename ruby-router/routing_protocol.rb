
def update_routing_table(update, router_ip)
  lines = update.split("\n")
  valid_time = lines[-1].split(' ')[1].to_i
  networks = lines[1..-2]
  networks.each do |network_with_mask|
    dev_name = find_interface_by_ip(router_ip.to_s)
    new_network = IPAddr.new(network_with_mask)
    if $routing_table[new_network]
      if $routing_table[new_network].type == 'dynamic'
        $routing_table[new_network].received = Time.now
        $routing_table[new_network].valid_time = valid_time
      end
    else
      $routing_table[new_network] = RoutingEntry.new(
                                    router_ip.to_s, dev_name,
                                    'dynamic',
                                    Time.now, valid_time)
     puts "learned a new network! #{new_network.to_s}"
    end
  end
end

def check_routing_table
  $routing_table.each do |ip_network, entry|
    next unless entry.type == 'dynamic'
    if Time.now - entry.received > entry.valid_time
      puts "connectivity to #{ip_network.to_s} lost"
      $routing_table.delete ip_network
    end
  end
end

$last_update_sent = Time.now
def send_updates
  if Time.now - $last_update_sent >= 2
    $last_update_sent = Time.now
    table_str = get_routing_table(true)
    update_str = "here_is_my_routing_table\n#{table_str}"
    send_on_all_interfaces(update_str)
  end
end
