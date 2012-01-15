module Proxee
  module Server
    attr_accessor :name

    def post_init
      @parser = Http::Parser.new
      @buffer = ""
      @proxy = self
      @mode = :http
      @server_socket = nil
      @name = UUID.generate

      @parser.on_headers_complete = proc do |h|
        host, port = h['Host'].split(':')
        port = (port || 80).to_i
        is_ssl = (port == 443)

        @mode = :ssl if is_ssl
        @server_socket = EM.connect(host, port, Proxee::Connection,
                                    # Custom params to the server socket
                                    @proxy, @buffer.dup, is_ssl)
        @buffer.clear
      end
    end

    def receive_data(data)
      if @mode == :ssl
        # Send data directly to the upstream server
        @server_socket.send_data(data)
      else
        @buffer << data; @parser << data
      end
    end
  end
end