module Proxee
  class Connection < EventMachine::Connection
    attr_accessor :client,
                  :data_received_from_upstream,
                  :data_to_send_upstream,
                  :http_header,
                  :http_body,
                  :is_ssl

    def initialize(*args)
      self.client, self.data_to_send_upstream, self.is_ssl = args
      self.data_received_from_upstream = ""
      self.http_body = ""
      self.http_header = ""

      @parser = Http::Parser.new

      @parser.on_headers_complete = proc { |header| self.http_header = header }
      @parser.on_body = proc { |chunk| self.http_body << chunk }
    end

    def connection_completed
      # If this is an SSL proxy (with an HTTP CONNECT header), we need
      # to send a HTTP/1.0 200 Connection Established response back to the client,
      # so that the client can start the SSL handshake.
      if self.is_ssl
        @client.send_data("HTTP/1.0 200 Connection established\r\n\r\n")
      else
        # Otherwise send data upstream
        send_data(self.data_to_send_upstream)
      end
    end

    # This is data received upstream from the server
    def receive_data(data)
      self.data_received_from_upstream << data
      @parser << data

      self.client.send_data(data)
      puts "Sending Data to Client: #{client.name}"
    end

    def unbind
      # Handle self.data_received_from_upstream (in case of SSL)
    end
  end
end
