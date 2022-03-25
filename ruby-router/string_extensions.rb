require 'ipaddr'

class String

  def as_l4_protocol
    case self[0].ord
      when 0x01 then 'icmp'
      when 0x06 then 'tcp'
      when 0x11 then 'udp'
      else 'unknown'
    end
  end
  
  def as_ipv4
    IPAddr.new(self.unpack('L>')[0], Socket::AF_INET)
  end
  
  def to_prefix_len
    self[0..-1].split('.').map do |octet|
      octet.to_i.chr.unpack('b*')
    end.join.count '1'
  end
  
  def as_mac_address
    mac_arr = Array.new
    self.each_byte do |byte|
      mac_arr << byte.to_i.to_s(16).rjust(2, '0')
    end
    mac_arr.join('-')
  end

  def as_ethertype
    case self.unpack('S>')[0]
      when 0x0800 then return 'IPv4'
      when 0x0806 then return 'ARP'
      else return 'unknown'
    end
  end

end
