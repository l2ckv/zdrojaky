

def load_config_file(filename)
  router_name = String.new
  int_names = Array.new
  File.open(filename).each do |line|
    next if line.length <= 1
    next if line[0] == '#'
    tokens = line.chomp.split(' ')
    case tokens[0]
    when 'router_name'
      router_name = tokens[1]
    when 'interface'
      int_names << tokens[1]
    end
  end
  return router_name, int_names
end
