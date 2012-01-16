module Proxee
  class Web < Sinatra::Base
    set :root, Pathname.new(__FILE__).dirname.parent.parent
    set :haml, :format => :html5

    get '/' do
      @events = Event.completed
      haml :index
    end
  end
end