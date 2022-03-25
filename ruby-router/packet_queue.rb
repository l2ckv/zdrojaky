
def add_packet_to_output_queue(ip_packet, gateway, int_out)
  ip_header = ip_packet[0..19]
  ip_data = ip_packet[20..-1]
  new_header = rebuild_ip_header(ip_header)
  if gateway == 'self'
    send_local new_header+ip_data, int_out
  else
    send_remote new_header+ip_data, gateway, int_out
  end
end

def rebuild_ip_header(ip_header)
  new_header = ip_header
  #new_header[10] = "\x00"
  #new_header[11] = "\x00"
  new_header
end

def send_local(ip_packet, int_out)
  dst_ip_uint32 = ip_packet[16..19].unpack('L>')[0]
  if mac_address_is_known? dst_ip_uint32
    dst_mac = $mac_table[dst_ip_uint32]
  else
    dst_mac = "\xFF"*6
  end
  src_mac = int_out.mac_address
  eth_frame = "#{dst_mac}#{src_mac}\x08\x00#{ip_packet}"
  int_out.send_packet(eth_frame)
end

def send_remote(ip_packet, gateway, int_out)
  tmp_ip = IPAddr.new(gateway)
  unless mac_address_is_known? tmp_ip.to_i
    puts "error: don't know gateway MAC address"
    return
  end
  dst_mac = $mac_table[tmp_ip.to_i]
  src_mac = int_out.mac_address
  eth_frame = "#{dst_mac}#{src_mac}\x08\x00#{ip_packet}"
  int_out.send_packet(eth_frame)
end

