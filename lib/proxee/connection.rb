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

      @parser.on_headers_complete = proc do |header|
        event = Proxee::Event.find(self.client.name)
        unless event.nil?
          event.response_headers = header.to_json
          event.response_code = @parser.status_code.to_i
          event.save
        end
      end

      @parser.on_body = proc do |chunk|
        event = Proxee::Event.find(self.client.name)
        unless event.nil?
          event.response_body = event.response_body.to_s + chunk
          event.save
        end
      end

      @parser.on_message_complete = proc do |env|
        event = Proxee::Event.find(self.client.name)
        unless event.nil?
          event.completed = 1
          event.save
        end
      end
    end

    def connection_completed
      # If this is an SSL proxy (with an HTTP CONNECT header), we need
      # to send a HTTP/1.0 200 Connection Established response back to the client,
      # so that the client can start the SSL handshake.
      # From: http://muffin.doit.org/docs/rfc/tunneling_ssl.html
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
      @parser << data unless is_ssl
      self.client.send_data(data)
    end

    def unbind
      # Handle self.data_received_from_upstream (in case of SSL)
      event = Proxee::Event.find(self.client.name)
      unless event.nil?
        event.response_body = event.response_body.to_s + self.data_received_from_upstream
        event.response_code = 200
        event.completed = 1
        event.save
      end
    end
  end
end
