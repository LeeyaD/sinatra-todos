require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/contrib'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'hello'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Renders new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if name is invalid. Returns nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name already taken.'
  end
end

# Creates new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Renders a page for an individual list
get '/lists/:id' do
  list_id = params[:id].to_i
  @list = session[:lists][list_id]
  erb :list, layout: :layout
end

# Edits an existing todo list
get '/lists/:id/edit' do
  list_id = params[:id].to_i
  @list = session[:lists][list_id]
  erb :edit_list, layout: :layout
end

# Update existing todo list
post '/lists/:id' do
  id = params[:id].to_i
  @list = session[:lists][id]
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name) if !(@list[:name] == list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'List updated successfully.'
    redirect "/lists/#{id}"
  end
end

# Deletes en existing list
post '/lists/:id/destroy' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Return an error message if name is invalid. Returns nil if name is valid.
def error_for_todo_name(name, id)
  if !(1..100).cover?(name.size)
    'Todo must be between 1 and 100 characters.'
  elsif session[:lists][id][:todos].any? { |todo| todo == name }
    'Todo is already listed.'
  end
end

# Adds a todo to an existing list
post '/lists/:id/todos' do
  id = params[:id].to_i
  todo = params[:todo].strip
  @list = session[:lists][id]
  error = error_for_todo_name(todo, id)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << todo
    session[:success] = 'Todo has been added.'
    redirect "/lists/#{id}"
  end
end

# post '/lists/:id/todos' do
#   id = params[:id].to_i
#   todo = params[:todo].strip
#   @list = session[:lists][id]
#   error = error_for_todo_name(todo, id)
#   @list[:todos] << todo
#   redirect "/lists/#{id}"
# end