list = {
  name: "Groceries",
  todos: [
    { name: "Buy milk", completed: true },
    { name: "Buy sugar", completed: false },
    { name: "Buy garlic", completed: true },
    { name: "Buy butter", completed: true }
  ]
}

def all_todos_complete?(list)
  list[:todos].all? do |todo|
    todo[:completed] == true
  end
end

p all_todos_complete?(list)