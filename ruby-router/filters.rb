

$filters = Array.new

def port_matches_range?(port, port_range)
  return true if port_range == 'any'
  if port_range.include?('-')
    tokens = port_range.split('-')
    min_port = tokens[0].to_i
    max_port = tokens[1].to_i
    return port.between?(min_port, max_port)
  else
    return port == port_range.to_i
  end
end

def should_be_filtered?(l4_protocol, src_ip, dst_ip, ip_data)
  unless l4_protocol == 'icmp'
    src_port = ip_data[0..1].unpack('S>')[0]
    dst_port = ip_data[2..3].unpack('S>')[0]
  end
  $filters.each do |fe|
    next if (fe.src_ip != src_ip.to_s) and (fe.src_ip != 'any')
    next if (fe.dst_ip != dst_ip.to_s) and (fe.dst_ip != 'any')
    next if (fe.protocol != l4_protocol) and (fe.protocol != 'any')
    unless l4_protocol == 'icmp'
      next unless port_matches_range?(src_port, fe.src_ports)
      next unless port_matches_range?(dst_port, fe.dst_ports)
    end
    return true
  end
  false
end
