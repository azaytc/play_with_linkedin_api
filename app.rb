require "rubygems"
require "haml"
require "sinatra"
require "linkedin"
require 'pry'
require "sinatra/reloader"

enable :sessions

helpers do
  def login?
    !session[:atoken].nil?
  end

  def profile
    linkedin_client.profile unless session[:atoken].nil?
  end

  def connections
    linkedin_client.connections unless session[:atoken].nil?
  end

  private
  def linkedin_client
    client = LinkedIn::Client.new(settings.api, settings.secret)
    client.authorize_from_access(session[:atoken], session[:asecret])
    client
  end 

end

configure do
  # get your api keys at https://www.linkedin.com/secure/developer
  set :api, ""
  set :secret, ""
end

get "/" do
  haml :index
end

get "/auth" do
  client = LinkedIn::Client.new(settings.api, settings.secret)
  binding.pry
  request_token = client.request_token(:oauth_callback => "http://#{request.host}/auth/callback")
  session[:rtoken] = request_token.token
  session[:rsecret] = request_token.secret

  redirect client.request_token.authorize_url
end

get "/auth/logout" do
   session[:atoken] = nil
   redirect "/"
end

get "/auth/callback" do
  client = LinkedIn::Client.new(settings.api, settings.secret)
  if session[:atoken].nil?
    pin = params[:oauth_verifier]
    atoken, asecret = client.authorize_from_request(session[:rtoken], session[:rsecret], pin)
    session[:atoken] = atoken
    session[:asecret] = asecret    
  end
  redirect "/"
end


__END__
@@index
-if login?
  %a{:href => "/auth/logout"} Logout
  %hr
  %strong #{profile.first_name} #{profile.last_name}
  %br
  %img{:src => linkedin_client.profile(:fields => ['picture-url']).picture_url} 
  %p= profile.headline

  %br
  %div= "You have #{connections.total} connections!"
  -connections.all.each do |c|
    %div= "#{c.first_name} #{c.last_name} - #{c.headline}"
  %hr 

-else
  %a{:href => "/auth"} Login using LinkedIn
