
before do
  unless %w(/login /signup).include?(request.path_info) or 
      request.path_info =~ /\.css$/ or 
      @logged_in_user = User.find_by_id(session["user_id"])
    redirect '/login', 303
  end
  puts "logged in as:#{@logged_in_user.username}" if @logged_in_user
end

get '/login' do
  erb :login
end

post '/login' do
  if user = User.find_by_username(params[:username]) and
      User.hash_pw(user.salt, params[:password]) == user.hashed_password
    session["user_id"] = user.id
    redirect '/'
  else
    @login_error = "Incorrect username or password"
    erb :login
  end
end

post '/signup' do
  if params[:username] !~ /^\w+$/
    @signup_error = "Username must only contain letters, numbers and underscores."
  elsif redis.key?("user:username:#{params[:username]}")
    @signup_error = "That username is taken."
  elsif params[:username].length < 4
    @signup_error = "Username must be at least 4 characters"
  elsif params[:password].length < 6
    @signup_error = "Password must be at least 6 characters!"
  elsif params[:password] != params[:password_confirmation]
    @signup_error = "Passwords do not match!"
  end
  if @signup_error
    erb :login
  else
    user = User.create(params[:username], params[:password])
    session["user_id"] = user.id
    redirect "/"
  end
end

get '/logout' do
  session["user_id"] = nil
  redirect '/login'
end
