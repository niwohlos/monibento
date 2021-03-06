require 'socket'
require 'stringio'

class Server
  def initialize(port, options)
    @port   = port
    @sleep  = options[:sleep] || 1
    @origin = options[:origin] || '*'
    @server = nil
  end

  def start(block = self.method(:ping))
    @server = TCPServer.new @port

    serve block
  end


  def stop
    @server = nil
  end

  protected

  def try_accept
    begin
      client = @server.accept_nonblock

    rescue IO::WaitReadable, Errno::EINTR
    end

    client
  end

  def serve(block)
    loop do
      break if @server.nil?

      connection = try_accept

      p connection

      if connection.nil?
        IO.select [@server]

        next
      end

      Thread.start(connection) do |client|
        greet(client)

        loop do
          event = update block

          client.print event

          sleep(@sleep)
        end
      end
    end
  end

  def greet(client)
    client.puts('HTTP/1.1 200 OK')
    client.puts('Content-type: text/event-stream')
    client.puts('Access-Control-Allow-Origin: ' + @origin)
    client.puts
    client.flush
  end

  def update(block)
    $stdout = StringIO.new

    block.call

    buffer  = $stdout
    $stdout = STDOUT

    buffer.rewind
    buffer.read
  end

  def ping
    puts 'event: ping'
    puts 'data: {"msg": "Hello, world!"}'
    puts
  end
end