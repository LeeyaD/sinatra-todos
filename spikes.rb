todos = [
  { id: 1, name: "Study for 1 hr", completed: false },
  { id: 2, name: "Attend meetup", completed: true },
  { id: 3, name: "Prep for ks-womens-group", completed: false },
  { id: 4, name: "take assessment", completed: true }
]



# Adding Identifiers to Lists
# 1. Reuse and/or create a simlar method to creating IDs for todos - DONE
# 2. Need to touch the following paths & views:
# 2a. PATH - 'Adding a new list' - DONE
# --- GENERATE a unique id #
# --- ADD id to list' hash

# 2b. VIEW - `lists.erb`
# --- Check if #sort_lists(@lists) or the block being passed to it `do |list, index|` need altering, e.g. we should no longer using the index in our href attribute
# --- Double check #todos_remaining(list) and #total_todos(list) too

# 2c. VIEW - `edit_list.erb`
# --- 

# 2b. 'Deleting a list'
# --- Make sure list is being deleted by id which should already be the unique ID and not it's index

# 2c. Anywhere `@list_id` is referenced
# --- view - `edit_list.erb`
# --- view - `list.erb`