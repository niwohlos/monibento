require_relative 'server'

class BroadcastServer < Server
  protected

  def serve(block)
    @clients = []

    loop do
      break if @server.nil?

      connection = try_accept

      unless connection.nil?
        greet connection

        @clients.push connection
      end

      if @clients.size.eql? 0
        IO.select [@server]

        next
      end

      event = update block

      @clients.each do |client|
        begin
          client.print event
        rescue Errno::EPIPE, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNRESET
          @clients.delete client
        end
      end

      sleep(@sleep)
    end
  end
end