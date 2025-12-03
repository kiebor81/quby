# Advanced Features

## Model Mapping

Map query results to Ruby objects instead of hashes.

### Define a Model

```ruby
class User
  attr_accessor :id, :name, :email, :age
  
  def initialize(attributes = {})
    attributes.each { |key, value| 
      send("#{key}=", value) if respond_to?("#{key}=") 
    }
  end
end
```

### Use with Queries

```ruby
db = QueryKit.connection

# get() with model
query = db.query('users').where('age', '>', 18)
users = db.get(query, User)  # Returns Array of User objects

# first() with model
user = db.first(query, User)  # Returns User or nil

# raw() with model
users = db.raw('SELECT * FROM users WHERE age > ?', 18, model_class: User)
```

### Benefits

- Type-safe object access: `user.name` instead of `user['name']`
- Easy to add methods to models
- Better IDE autocomplete
- Works with any class that accepts a hash in `initialize`

## Repository Pattern

Clean data access layer with reusable queries.

### Basic Repository

```ruby
class User
  attr_accessor :id, :name, :email, :age
  
  def initialize(attributes = {})
    attributes.each { |key, value| 
      send("#{key}=", value) if respond_to?("#{key}=") 
    }
  end
end

class UserRepository < QueryKit::Repository
  table 'users'
  model User
end

# Use with global config
QueryKit.setup(:sqlite, database: 'app.db')
repo = UserRepository.new

# Or with explicit connection
db = QueryKit.connect(:sqlite, 'app.db')
repo = UserRepository.new(db)
```

### Built-in Methods

```ruby
# Find by ID
user = repo.find(1)                    # Returns User or nil

# Find by column
user = repo.find_by('email', 'alice@example.com')

# Get all
users = repo.all                       # Returns Array of Users

# WHERE queries
users = repo.where('age', '>', 18)
users = repo.where('age', 'BETWEEN', [20, 30])

# WHERE IN / NOT IN
users = repo.where_in('id', [1, 2, 3])
users = repo.where_not_in('status', ['banned', 'deleted'])

# Utilities
user = repo.first                      # First record
count = repo.count                     # Total count
exists = repo.exists?(1)               # Check if ID exists

# CRUD
id = repo.create(name: 'Alice', email: 'alice@test.com', age: 28)
id = repo.insert(...)                  # Alias for create

affected = repo.update(1, name: 'Alice Updated', age: 29)
affected = repo.delete(1)
affected = repo.destroy(1)             # Alias for delete

# Bulk delete
affected = repo.delete_where(status: 'inactive')
```

### Custom Repository Methods

```ruby
class UserRepository < QueryKit::Repository
  table 'users'
  model User
  
  def find_by_email(email)
    find_by('email', email)
  end
  
  def adults
    where('age', '>=', 18)
  end
  
  def active_users_in_country(country)
    execute(
      db.query(table_name)
        .where('status', 'active')
        .where('country', country)
        .order_by('name')
    )
  end
end

# Use custom methods
repo = UserRepository.new
adults = repo.adults
user = repo.find_by_email('alice@test.com')
```

### Transactions

```ruby
repo = UserRepository.new

repo.transaction do
  repo.create(name: 'Bob', email: 'bob@test.com')
  repo.update(1, status: 'active')
  # Commits on success, rolls back on error
end
```

## Transactions

All adapters support transactions:

```ruby
db = QueryKit.connection

db.transaction do
  # Insert
  user_id = db.execute_insert(
    db.insert('users').values(name: 'Alice', email: 'alice@test.com')
  )
  
  # Update
  db.execute_update(
    db.update('profiles').set(user_id: user_id).where('id', 1)
  )
  
  # Automatically commits if no errors
  # Automatically rolls back on exception
end
```

## Architecture

Quby uses clean separation of concerns:

- **Query builders** - Build SQL with fluent API (SELECT, INSERT, UPDATE, DELETE)
- **Adapters** - Database-specific implementations (SQLite, PostgreSQL, MySQL)
- **Connection** - Query execution and transaction management
- **Repository** - Optional data access pattern
- **Configuration** - Global connection management

All query builders are lazy - they only build SQL strings. Execute with:
- `db.get(query)` - Returns array of results
- `db.first(query)` - Returns first result
- `db.execute_insert(query)` - Returns last_insert_id
- `db.execute_update(query)` - Returns affected_rows
- `db.execute_delete(query)` - Returns affected_rows
- `db.raw(sql, *bindings)` - Execute raw SQL

## What Quby Does NOT Do

Intentionally excluded features:

- **No migrations** - Use a separate tool
- **No associations** - Write JOINs explicitly
- **No validations** - Handle in your models or business logic
- **No callbacks** - Keep business logic explicit
- **No schema introspection** - You define your models
- **No automatic timestamps** - Set them manually if needed

This is by design. Quby is a query builder, not a full ORM.
