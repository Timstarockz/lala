#
# lala.rb (server.rb)
# by Tim :D
#

require 'sinatra'

require 'json'
require 'date'
require 'net/http'
require 'open-uri'
require 'ipaddr'

require_relative "ext.rb"
require_relative "postman.rb"

# UI/MAIN
get '/' do
  uri = URI("http://localhost:4567/api/statuses.json")
  results = Net::HTTP.get(URI(uri))
  data = JSON.parse(results)
  @statuses = data["statuses"]
  
  if params[:text]
    #got input?
    text = params[:text]
    uri = URI("http://localhost:4567/api/post.json")
    req = Net::HTTP::Post.new(URI(uri))
    req.set_form_data('text' => text, 'user' => 'Tim_Web')

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    #{URI::encode(text)}&user=Tim_Web
  end
  
  erb :index
end

# API Documentation
get '/api' do
  erb :api
end

#TO-DO Add Sign Up Form
get '/sign_up' do
  erb :sign_up
end
#

# ---------- API -----------

# Post new status to LaLa
#
# Params:
#
# text (r)
# user (r) - tmp
#

post '/api/post.json' do
  content_type :json
  
  status = {}
  if params[:text]
    status[:text] = params[:text]
    status[:user] = params[:user]
    status[:id] = SecureRandom.uuid
    status[:date] = Time.now
    
    mp = Postman.new(status)
    
    status 200
    mp.to_s
  else
    #handle error
    status 403
    error = {
      erorr: "param 'text' is required to use this API call"
    }
    error.to_json
  end
end
#

# Delete a status from LaLa
#
# Params:
#
# id (r)
#

delete '/api/delete.json' do
  content_type :json
  
  if params[:id]
    #handle delete tweet from status_box
  else
    #handle error
    status 403
    error = {
      erorr: "param 'id' is required to use this API call"
    }
    error.to_json
  end
end
#

# Get all public statuses
#
# Params:
#
# count
# 

get '/api/statuses.json' do
  content_type :json
  
  status 200
  file = File.read("status_box.json")
  file
end
#

# Favorite a status
#
# Params:
#
# id
#

get '/api/status/favorite.json' do
  content_type :json
end
#


#---------------------------------------------------------------------------------


#
#kill switch
get '/api/kill_all' do
  password = params[:passcode]
  if password == "MakeNoHugs!"
    File.delete("status_box.json")
    "<b>You'll never know what you had until it's gone...</b>"
  else
    ipaddr3 = IPAddr.new
    string = "#{ipaddr3} just attempted the kill_switch"
    puts_s(string)
    #uri = URI("http://localhost:4567/api/post.json?text=#{string}&user=Lala")
    #results = Net::HTTP.get(URI(uri))
    
    "<b>Nice Try.</b>"
  end
end

delete '/api/kill_all' do
  password = params[:passcode]
  if password == "MakeNoHugs!"
    File.delete("status_box.json")
    "<b>You'll never know what you had until it's gone...</b>"
  else
    #ipaddr3 = IPAddr.new
    #string = "#{ipaddr3} just attempted the kill_switch"
    #uri = URI("http://localhost:4567/api/post.json?text=#{string}&user=Lala")
    #results = Net::HTTP.get(URI(uri))
    
    "<b>Nice Try.</b>"
  end
end
#



#test
get '/api/test.json' do
  content_type :json
  
  puts_s(params)
  
  # [id, status, name]
  a1 = ["28", "Hey this is a status for testing stuff cuz i like testing cool stuff", "@tim"]
  a2 = [a1, a1, a1]
  if params[:count]
    c = params[:count]
    a2 = []
    c.to_i.times do
      a2.push(a1)
    end
  else
    a2 = []
    a2.push(a1)
  end
  
  a2.to_json
end
#


#