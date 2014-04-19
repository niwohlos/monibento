require 'json'
require 'getoptlong'

require_relative 'lib/log'
require_relative 'lib/convenient_hash_access'
require_relative 'lib/server'
require_relative 'lib/broadcast_server'

hostname = Socket.gethostname
verbose  = false
origin = '*'

opts = GetoptLong.new(
    [ '--hostname', '-h', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
    [ '--origin', '-o', GetoptLong::REQUIRED_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
  when '--hostname'
    hostname = arg
  when '--verbose'
    verbose = true
  when '--origin'
    origin = arg
  end
end

log = Log.new(verbose)

log.info("monibento starting on host #{hostname}")


server = BroadcastServer.new(3334, origin: origin, sleep: 2)
server.start Proc.new {
  @data_old = @data_new.dup unless @data_new.nil?
  @data_new = []

  data    = { host: hostname, cpu: [], memory: {} }

  stat = File.read '/proc/stat'
  memstat = File.read '/proc/meminfo'

  mems = memstat.lines.select do |line|
    line[/^\s*(?:MemTotal|MemFree|Buffers|Cached|SwapTotal|SwapFree)/]
  end

  mems.each_with_index do |mem, index|
    mem[/^\s*(\w+):\s*(\d+)\s*(\w*)/]

    amount = $2.to_i

    case $3
    when 'kB'
      amount *= 1024
    when 'MB'
      amount *= 1024 * 1024
    else
    end

    case $1
    when 'MemTotal'
      data.memory.total = amount
    when 'MemFree'
      data.memory.free = amount
    when 'Buffers'
      data.memory.buffers = amount
    when 'Cached'
      data.memory.cached = amount
    when 'SwapTotal'
      data.memory.swap_total = amount
    when 'SwapFree'
      data.memory.swap_free = amount
    else
    end
  end

  cpus = stat.lines.select do |line|
    line[/^cpu\d+/]
  end

  cpus.each_with_index do |cpu, index|
    cpu.gsub! /\n/, ''

    cpu[/((?:\d+\s+){9}\d+)$/]

    values = $1.split /\s+/

    values.map! do |value|
      value.to_i
    end

    values << values.inject do |value, sum|
      sum += value
    end

    @data_new.push values.dup

    next if @data_old.nil?

    values = (0...10).map do |value_index|
      if (@data_new[index][10] - @data_old[index][10] == 0.0)
        (@data_new[index][value_index] - @data_old[index][value_index]).to_f
      else
        (@data_new[index][value_index] - @data_old[index][value_index]).to_f / (@data_new[index][10] - @data_old[index][10]).to_f
      end
    end

    keys = %i[ user nice system idle iowait irq softirq steal guest guest_nice]

    data.cpu.push Hash[keys.zip(values)]
  end

  puts 'event: resources'
  puts 'data: ' + data.to_json
  puts
}
