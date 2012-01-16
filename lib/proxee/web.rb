module Proxee
  class Web < Sinatra::Base
    set :root, Pathname.new(__FILE__).dirname.parent.parent
    set :haml, :format => :html5

    helpers do
      def escape_javascript(javascript)
        js_escape_map = {
          '\\'    => '\\\\',
          '</'    => '<\/',
          "\r\n"  => '\n',
          "\n"    => '\n',
          "\r"    => '\n',
          '"'     => '\\"',
          "'"     => "\\'"
        }

        if javascript
          result = javascript.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { |match| js_escape_map[match] }
          result
        else
          ''
        end
      end
    end

    get '/' do
      @events = Event.completed
      haml :index
    end

    get '/events/:id' do
      @event = Event.find(params[:id])
      content_type 'text/javascript'
      erb :'event.js'
    end

  end
end