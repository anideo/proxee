module Proxee
  class Event
    attr_accessor :request, :response, :id

    def initialize(opts = {})
      opts[:id] = UUID.generate if opts[:id].nil? || opts[:id].length == 0
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }
    end

    def save
      query = self.class.db.prepare "INSERT INTO events(id, request, response) VALUES (?, ?, ?)"
      result = query.execute(self.id, self.request, self.response)
      result
    end

    def self.find(id)
      query = self.db.prepare "SELECT id, request, response FROM events where id = ?"
      row = query.execute(id).first
      row.nil? ? nil : self.new(:id => row[0], :request => row[1], :response => row[2])
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