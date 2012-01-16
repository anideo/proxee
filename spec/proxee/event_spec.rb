require 'spec_helper'

describe Proxee::Event do
  before(:all) do
    @database = Proxee::Event.db
  end

  after(:each) do
    @database.execute("DELETE FROM events WHERE id IS NOT NULL")
  end

  describe "#initialize" do
    context "vanilla constructor" do
      before do
        @event = Proxee::Event.new(:id => 'abc', :request_headers => 'req', :response_headers => 'resp')
      end

      it "should initialize all the instance variables correctly" do
        @event.id.should == 'abc'
        @event.request_headers.should == 'req'
        @event.response_headers.should == 'resp'
        @event.persisted.should be_false
        @event.completed.should == 0
      end
    end

    context "id is not present as part of the constructor" do
      before do
        UUID.stub!(:generate) { 'fake-id' }
        @event = Proxee::Event.new(:request_headers => 'req', :response_headers => 'resp')
      end

      it "should initialize all the instance variables correctly" do
        @event.id.should == 'fake-id'
        @event.request_headers.should == 'req'
        @event.response_headers.should == 'resp'
        @event.persisted.should be_false
      end
    end
  end

  describe "#save" do
    before do
      @event = Proxee::Event.new(:id => 'fake_id', :request_headers => 'req', :response_headers => 'res')
    end

    context "new record" do
      it "should save the record to the in-memory SQLite database" do
        @event.save

        query = @database.prepare("SELECT id, request_headers, response_headers FROM events where id = ?")
        row = query.execute('fake_id').first

        row[0].should == 'fake_id'
        row[1].should == 'req'
        row[2].should == 'res'

        @event.persisted.should be_true
      end
    end

    context "existing record" do
      it "should save the record with the updated value" do
        @event.request_headers = 'new_req'
        @event.save

        query = @database.prepare("SELECT id, request_headers, response_headers FROM events where id = ?")
        row = query.execute('fake_id').first

        row[0].should == 'fake_id'
        row[1].should == 'new_req'
        row[2].should == 'res'
      end
    end
  end

  describe ".find" do
    context "requested record exists" do
      before do
        query = @database.prepare("INSERT INTO events(id, request_headers, response_headers) VALUES(?, ?, ?)")
        query.execute('fake_id', 'req', 'res')
      end

      it "should return the event associated with the event ID fake_id" do
        event = Proxee::Event.find('fake_id')

        event.id.should == 'fake_id'
        event.request_headers.should == 'req'
        event.response_headers.should == 'res'

        event.persisted.should be_true
      end
    end

    context "requested record does not exist" do
      it "should return a nil object" do
        event = Proxee::Event.find('fake_id')
        event.should be_nil
      end
    end
  end

  describe ".create" do
    before do
      @event = Proxee::Event.create(:id => 'fake_id', :request_headers => 'req', :response_headers => 'res')
    end

    context "new record" do
      it "should save the record to the in-memory SQLite database" do
        query = @database.prepare("SELECT id, request_headers, response_headers FROM events where id = ?")
        row = query.execute('fake_id').first

        row[0].should == 'fake_id'
        row[1].should == 'req'
        row[2].should == 'res'

        @event.persisted.should be_true
      end
    end
  end

  describe ".completed" do
    before do
      @now = Time.now

      Timecop.freeze(@now - 5.minutes) do
        @event_1 = Proxee::Event.create(:request_header => 'req_1', :response_headers => 'rsp_1', :completed => 1)
      end

      Timecop.freeze(@now - 2.minutes) do
        @event_2 = Proxee::Event.create(:request_header => 'req_2', :response_headers => 'rsp_2', :completed => 1)
      end

      Timecop.freeze(@now - 1.minute) do
        # This one is not complete yet
        @event_3 = Proxee::Event.create(:request_header => 'req_2')
      end
    end

    context "without since parameter" do
      it "should return all events" do
        Proxee::Event.completed.should == [@event_2, @event_1]
      end
    end
  end
end