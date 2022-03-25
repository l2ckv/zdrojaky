def hex_value(character)
  if character <= '9'.ord
    character - '0'.ord
  else
    character - 'a'.ord + 10
  end
end

class FFI::Pcap::Live

  def mac_address
    return @real_mac if @real_mac
    result = %x[ifconfig | grep #{self.device}]
    mac_address = result.split(' ')[-1].split(':')
    @real_mac = String.new
    mac_address.each do |str|
      n1 = hex_value str[0].ord
      n2 = hex_value str[1].ord
      tmp = n1 * 16 + n2
      @real_mac += tmp.chr
    end
    @real_mac
  end
  
  def broadcast_address
    return @bcast_addr if @bcast_addr
    result = %x[ifconfig | grep -A1 #{self.device}]
    bcast_str = result.split(' ').find { |token|
      token.include?('Bcast')
    }
    @bcast_addr = bcast_str.split(':')[1]
  end
  
  def ip_address
    return @ip_address if @ip_address
    result = %x[ifconfig | grep -A1 #{self.device}]
    ip_str = result.split(' ').find { |token|
      token.include?('addr') and not token.include?('HW')
    }
    @ip_address = ip_str.split(':')[1]
  end

end
