require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/contrib'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'

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

  def create_hash(collection)
    h = {}
    collection.each_with_index do |item, index|
      h[item] = index
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

# Assign unique id to lists/todos
def next_element_id(elements)
  max = elements.map { |element| element[:id] }.max || 0
  max + 1
end

# Returns list via list_id
def load_lists(list_id)
  list = session[:lists].select { |list| list[:id] == list_id }
  return list[0] if !list.empty?

  session[:error] = "That list does not exist."
  redirect '/lists'
end

# Return an error message if name is invalid. Returns nil if name is valid.
def name_error(name, elements=session[:lists])
  if !(1..100).cover?(name.size)
    'Name must be between 1 and 100 characters.'
  elsif elements.any? { |element| element[:name] == name }
    'Name already taken.'
  end
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

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = name_error(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_element_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
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

# Update an existing list
post '/lists/:id' do
  id = params[:id].to_i
  @list = load_lists(id)
  list_name = params[:list_name].strip
  
  error = name_error(list_name) if !(@list[:name] == list_name)
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
  session[:lists].delete_if { |list| list[:id] == id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = 'The list has been deleted.'
    redirect '/lists'
  end
end

# Adds a todo to an existing list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)
  todo = params[:todo].strip

  error = name_error(todo, @list[:todos])
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos])
    @list[:todos] << { id: id, name: todo, completed: false }

    session[:success] = 'Todo has been added to list.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete the todo
post '/lists/:list_id/todos/:todo_id/destroy' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)
  
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_if { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = 'The todo has been deleted.'
    redirect "/lists/#{@list_id}"
  end
end

#  Update the status of the todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_lists(@list_id)

  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  todo[:completed] = is_completed

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
