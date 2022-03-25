require 'ipaddr'
require './string_extensions'

$mac_table = Hash.new

def learn_mac_addresses(eth_header, ip_packet)
  src_mac = eth_header[6...12]
  protocol = eth_header[12..13].as_ethertype
  return if protocol == 'unknown'
  src_ip_uint32 = ip_packet[12..15].unpack('L>')[0]
  unless mac_address_is_known?(src_ip_uint32)
    $mac_table[src_ip_uint32] = src_mac
    tmp_ip = IPAddr.new(src_ip_uint32, Socket::AF_INET)
    puts "#{tmp_ip.to_s} is at #{src_mac.as_mac_address}"
  end
end

def mac_address_is_known?(dst_ip_uint32)
  $mac_table.has_key?(dst_ip_uint32)
end
