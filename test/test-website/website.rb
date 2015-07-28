require 'sinatra'

set :port, 8080

get '/:name' do
  p "this is the page name #{params['name']}"
  File.read("./test/test-website/#{params['name']}")
end