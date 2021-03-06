module Proxee
  class Event
    attr_accessor :request_headers, :request_body, :request_verb,
                  :request_url, :request_query,
                  :response_headers, :response_body, :response_code,
                  :id, :persisted, :completed_at

    def initialize(opts = {})
      opts[:id] = UUID.generate if opts[:id].blank?

      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }

      self.persisted = false
    end

    def save
      _completed_at = self.completed_at.present? ? self.completed_at.strftime("%Y-%m-%d %H:%M:%S") : nil

      if self.persisted
        query = self.class.db.prepare "UPDATE events SET request_headers = ?, request_body = ?, request_verb = ?, request_url = ?, request_query = ?, response_headers = ?, response_body = ?, response_code = ?, completed_at = ? WHERE id = ?"
        query.execute(self.request_headers, self.request_body, self.request_verb, self.request_url, self.request_query, self.response_headers, self.response_body, self.response_code, _completed_at, self.id)
      else
        query = self.class.db.prepare "INSERT INTO events(id, request_headers, request_body, request_verb, request_url, request_query, response_headers, response_body, response_code, created_at, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        query.execute(self.id, self.request_headers, self.request_body, self.request_verb, self.request_url, self.request_query, self.response_headers, self.response_body, self.response_code, Time.now.strftime("%Y-%m-%d %H:%M:%S"), _completed_at)
      end

      self.persisted = true
    end

    def ==(_event)
      self.id == _event.id
    end

    def self.find(id)
      query = self.db.prepare "SELECT id, request_headers, request_body, request_verb, request_url, request_query, response_headers, response_body, response_code, completed_at FROM events where id = ?"
      row = query.execute(id).first
      if row.nil?
        nil
      else
        self.new(:id => row[0], :request_headers => row[1], :request_body => row[2], :request_verb => row[3],
                                :request_url => row[4], :request_query => row[5],
                                :response_headers => row[6], :response_body => row[7], :response_code => row[8].to_i).tap do |e|
          e.completed_at = row[9]
          e.persisted = true
        end
      end
    end

    def self.create(opts)
      Proxee::Event.new(opts).tap { |e| e.save }
    end

    def self.completed(opts = {})
      since = opts[:since]

      rows = self.db.execute("SELECT id, request_headers, request_body, request_verb, " +
                             "request_url, request_query, response_headers, response_body, " +
                             "response_code, completed_at, created_at FROM events " +
                             "WHERE completed_at IS NOT NULL " +
                             "ORDER BY created_at DESC")
      rows.map do |row|
        self.new(:id => row[0], :request_headers => row[1], :request_body => row[2], :request_verb => row[3],
                                :request_url => row[4], :request_query => row[5],
                                :response_headers => row[6], :response_body => row[7], :response_code => row[8].to_i).tap do |e|
          e.completed_at = row[9]
          e.persisted = true
        end
      end
    end

    # Class Methods
    def self.db
      @@__db ||= begin
        SQLite3::Database.new(ENV['FS_DB'] ? 'proxee.db' : ':memory:', :type_translation => true).tap do |db|
          row = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='events'").first
          if row.nil?
            db.execute(<<-SQL)
              CREATE TABLE events (
                id STRING PRIMARY KEY,
                request_headers TEXT,
                request_body TEXT,
                request_verb STRING,
                request_url TEXT,
                request_query TEXT,
                response_headers TEXT,
                response_body TEXT,
                response_code INTEGER,
                completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
              )
            SQL
          end
        end
      end
    end

  end
end