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
        @event = Proxee::Event.new(:id => 'abc', :request => 'req', :response => 'resp')
      end

      it "should initialize all the instance variables correctly" do
        @event.id.should == 'abc'
        @event.request.should == 'req'
        @event.response.should == 'resp'
      end
    end

    context "id is not present as part of the constructor" do
      before do
        UUID.stub!(:generate) { 'fake-id' }
        @event = Proxee::Event.new(:request => 'req', :response => 'resp')
      end

      it "should initialize all the instance variables correctly" do
        @event.id.should == 'fake-id'
        @event.request.should == 'req'
        @event.response.should == 'resp'
      end
    end
  end

  describe "#save" do
    before do
      @event = Proxee::Event.new(:id => 'fake_id', :request => 'req', :response => 'res')
      @event.save
    end

    it "should save the record to the in-memory SQLite database" do
      query = @database.prepare("SELECT id, request, response FROM events where id = ?")
      row = query.execute('fake_id').first

      row[0].should == 'fake_id'
      row[1].should == 'req'
      row[2].should == 'res'
    end
  end

  describe ".find" do
    context "requested record exists" do
      before do
        query = @database.prepare("INSERT INTO events(id, request, response) VALUES(?, ?, ?)")
        query.execute('fake_id', 'req', 'res')
      end

      it "should return the event associated with the event ID fake_id" do
        event = Proxee::Event.find('fake_id')

        event.id.should == 'fake_id'
        event.request.should == 'req'
        event.response.should == 'res'
      end
    end

    context "requested record does not exist" do
      it "should return a nil object" do
        event = Proxee::Event.find('fake_id')
        event.should be_nil
      end
    end
  end

end