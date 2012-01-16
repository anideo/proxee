module Proxee
  class Event
    attr_accessor :request, :response, :id, :persisted

    def initialize(opts = {})
      opts[:id] = UUID.generate if opts[:id].nil? || opts[:id].length == 0
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }

      self.persisted = false
    end

    def save
      if self.persisted
        query = self.class.db.prepare "UPDATE events SET request = ? AND response = ? WHERE id = ?"
        query.execute(self.request, self.response, self.id)
      else
        query = self.class.db.prepare "INSERT INTO events(id, request, response) VALUES (?, ?, ?)"
        query.execute(self.id, self.request, self.response)
      end

      self.persisted = true
    end

    def self.find(id)
      query = self.db.prepare "SELECT id, request, response FROM events where id = ?"
      row = query.execute(id).first
      if row.nil?
        nil
      else
        event = self.new(:id => row[0], :request => row[1], :response => row[2])
        event.persisted = true
        event
      end
    end

    # Class Methods
    def self.db
      @@__db ||= begin
        SQLite3::Database.new(':memory:', :type_translation => true).tap do |db|
          db.execute(<<-SQL)
            CREATE TABLE events (
              id STRING PRIMARY KEY,
              request TEXT,
              response TEXT,
              created_at DATETIME DEFAULT CURRENT_DATETIME
            )
          SQL
        end
      end
    end

  end
end