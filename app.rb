
require 'rubygems'
require 'sinatra'  
require 'erb'
require 'redis'

require 'domain'
require 'login-signup'

set :sessions, true

def redis
  $redis ||= Redis.new
end

before do
  keys = redis.keys("*")
end

get '/' do
  @posts = @logged_in_user.timeline
  erb :index
end

get '/timeline' do
  @posts = Timeline.page(1)
  erb :timeline
end

post '/post' do
  if params[:content].length == 0
    @posting_error = "You didn't enter anything."
  elsif params[:content].length > 140
    @posting_error = "Keep it to 140 characters please!"
  end
  if @posting_error
    @posts = @logged_in_user.timeline
    erb :index
  else
    Post.create(@logged_in_user, params[:content])
    redirect '/'
  end
end

get '/:follower/follow/:followee' do |follower_username, followee_username|
  follower = User.find_by_username(follower_username)
  followee = User.find_by_username(followee_username)
  follower.follow(followee)
  redirect "/" + followee_username
end

get '/:follower/stopfollow/:followee' do |follower_username, followee_username|
  follower = User.find_by_username(follower_username)
  followee = User.find_by_username(followee_username)
  follower.stop_following(followee)
  redirect "/" + followee_username
end

get '/:username' do |username|
  @user = User.find_by_username(username)
  
  @posts = @user.posts
  @followers = @user.followers
  @followees = @user.followees
  erb :profile
end

get '/:username/mentions' do |username|
  @user = User.find_by_username(username)
  @posts = @user.mentions
  erb :mentions
end

helpers do
  def link_to_user(user)
    f = <<-HTML
<a href="/#{user.username}">#{user.username}</a>
    HTML
  end
  
  def pluralize(singular, plural, count)
    if count == 1
      count.to_s + " " + singular
    else
      count.to_s + " " + plural
    end
  end
  
  def display_post(post)
    post.content.gsub(/@\w+/) do |mention|
      if user = User.find_by_username(mention[1..-1])
        "@" + link_to_user(user)
      else
        mention
      end
    end
  end

  def time_ago_in_words(time)
    distance_in_seconds = (Time.now - time).round
    case distance_in_seconds
    when 0..10
      return "just now"
    when 10..60
      return "less than a minute ago"
    end
    distance_in_minutes = (distance_in_seconds/60).round
    case distance_in_minutes
    when 0..1
      return "a minute ago"
    when 2..45
      return distance_in_minutes.round.to_s + " minutes ago"
    when 46..89
      return "about an hour ago"
    when 90..1439        
      return (distance_in_minutes/60).round.to_s + " hours ago"
    when 1440..2879
      return "about a day ago"
    when 2880..43199
      (distance_in_minutes / 1440).round.to_s + " days ago"
    when 43200..86399
       "about a month ago"
    when 86400..525599   
      (distance_in_minutes / 43200).round.to_s + " months ago"
    when 525600..1051199
      "about a year ago"
    else
      "over " + (distance_in_minutes / 525600).round.to_s + " years ago"
    end
  end
end
        





