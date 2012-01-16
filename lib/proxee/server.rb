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
      @event = nil

      @parser.on_headers_complete = proc do |header|
        host, port = header['Host'].split(':')
        port = (port || 80).to_i
        is_ssl = (port == 443)

        @event = Proxee::Event.create(:id => @name,
                                      :request_headers => header.to_json,
                                      :request_url => @parser.request_url,
                                      :request_verb => @parser.http_method,
                                      :request_query => @parser.query_string)

        @mode = :ssl if is_ssl
        @server_socket = EM.connect(host, port, Proxee::Connection,
                                    # Custom params to the server socket
                                    @proxy, @buffer.dup, is_ssl)
        @buffer.clear
      end

      @parser.on_body = proc do |chunk|
        event = Event.find(name)
        unless event.nil?
          event.request_body = event.request_body.to_s + chunk
          event.save
        end
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