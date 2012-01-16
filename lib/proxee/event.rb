module Proxee
  class Event
    attr_accessor :request_headers, :request_body,
                  :response_headers, :response_body,
                  :id, :persisted

    def initialize(opts = {})
      opts[:id] = UUID.generate if opts[:id].nil? || opts[:id].length == 0
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }

      self.persisted = false
    end

    def save
      if self.persisted
        query = self.class.db.prepare "UPDATE events SET request_headers = ?, request_body = ?, response_headers = ?, response_body = ? WHERE id = ?"
        query.execute(self.request_headers, self.request_body, self.response_headers, self.response_body, self.id)
      else
        query = self.class.db.prepare "INSERT INTO events(id, request_headers, request_body, response_headers, response_body) VALUES (?, ?, ?, ?, ?)"
        query.execute(self.id, self.request_headers, self.request_body, self.response_headers, self.response_body)
      end

      self.persisted = true
    end

    def self.find(id)
      query = self.db.prepare "SELECT id, request_headers, request_body, response_headers, response_body FROM events where id = ?"
      row = query.execute(id).first
      if row.nil?
        nil
      else
        self.new(:id => row[0], :request_headers => row[1], :request_body => row[2], :response_headers => row[3], :response_body => row[4]).tap do |e|
          e.persisted = true
        end
      end
    end

    # Class Methods
    def self.db
      @@__db ||= begin
        SQLite3::Database.new(':memory:', :type_translation => true).tap do |db|
          db.execute(<<-SQL)
            CREATE TABLE events (
              id STRING PRIMARY KEY,
              request_headers TEXT,
              request_body TEXT,
              response_headers TEXT,
              response_body TEXT,
              created_at DATETIME DEFAULT CURRENT_DATETIME
            )
          SQL
        end
      end
    end

  end
end