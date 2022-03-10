require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/contrib'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'hello'

  set :erb, :escape_html => true
end

helpers do
  def todos_remaining(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def total_todos(list)
    list[:todos].size
  end

  def completed_list?(list)
    (total_todos(list) > 0) && (todos_remaining(list) == 0)
  end

  def list_class(list)
    "complete" if completed_list?(list)
  end

  def todo_class(todo)
    "complete" if todo[:completed]
  end

  def create_hash(lists)
    h = {}
    lists.each_with_index do |list, index|
      h[list] = index
    end
    h
  end

  def sort_lists(lists, &block)
    sorted = create_hash(lists).sort_by do |list, _|
      completed_list?(list) ? 1 : 0
    end
    sorted.each(&block)
  end

  def sort_todos(todos, &block)
    sorted = create_hash(todos).sort_by do |todo, _|
      todo[:completed] ? 1 : 0
    end
    sorted.each(&block)
  end
end

before do
  session[:lists] ||= []
end

def load_lists(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "That list does not exist."
  redirect '/lists'
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

# Create a new list
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

# Show an individual list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = load_lists(@list_id)

  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  list_id = params[:id].to_i
  @list = load_lists(list_id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  id = params[:id].to_i
  @list = load_lists(id)
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

# Delete an existing list
post '/lists/:id/destroy' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Return an error message if name is invalid. Returns nil if name is valid.
def error_for_todo(name, id)
  if !(1..100).cover?(name.size)
    'Todo must be between 1 and 100 characters.'
  elsif session[:lists][id][:todos].any? { |todo| todo == name }
    'Todo is already listed.'
  end
end

# Adds a todo to an existing list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)
  todo = params[:todo].strip

  error = error_for_todo(todo, @list_id)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = 'Todo has been added to list.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete the todo
post '/lists/:list_id/todos/:todo_id/destroy' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)

  @todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(@todo_id)
  session[:success] = 'The todo has been deleted.'
  redirect "/lists/#{@list_id}"
end

#  Update the status of the todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)
  @todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == "true"
  @list[:todos][@todo_id][:completed] = is_completed
  session[:success] = 'Todo has been updated.'
  redirect "/lists/#{@list_id}"
end

# Marks all todos complete
post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i
  @list = load_lists(@list_id)

  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = 'All todos have been completed.'
  redirect "/lists/#{@list_id}"
end
