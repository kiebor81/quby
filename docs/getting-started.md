# Getting Started with Quby

## Installation

Add the database driver you need:

```bash
gem install sqlite3      # For SQLite
gem install pg           # For PostgreSQL
gem install mysql2       # For MySQL
```

Copy the `lib/quby` folder to your project.

## Configuration

### Global Configuration (Recommended)

Configure once at application startup:

```ruby
require_relative 'lib/quby'

# Block style
QueryKit.configure do |config|
  config.adapter = :sqlite
  config.connection_options = { database: 'db/app.db' }
end

# Shorthand
QueryKit.setup(:sqlite, database: 'db/app.db')

# Use anywhere
db = QueryKit.connection
```

### Environment-Specific

```ruby
case ENV['RACK_ENV']
when 'development'
  QueryKit.setup(:sqlite, database: 'db/development.db')
when 'test'
  QueryKit.setup(:sqlite, database: ':memory:')
when 'production'
  QueryKit.setup(:postgresql,
    host: ENV['DB_HOST'],
    dbname: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  )
end
```

### Direct Connection

For scripts or multiple databases:

```ruby
db = QueryKit.connect(:sqlite, 'database.db')
db = QueryKit.connect(:postgresql, host: 'localhost', dbname: 'mydb', user: 'postgres', password: 'pass')
db = QueryKit.connect(:mysql, host: 'localhost', database: 'mydb', username: 'root', password: 'pass')
```

## Basic Usage

### SELECT

```ruby
db = QueryKit.connection

# Build query
query = db.query('users')
  .select('id', 'name', 'email')
  .where('age', '>', 18)
  .order_by('name')
  .limit(10)

# Execute
users = db.get(query)           # Returns array of hashes
user = db.first(query)          # Returns first result or nil
```

### INSERT

```ruby
query = db.insert('users').values(
  name: 'John Doe',
  email: 'john@example.com',
  age: 30
)

id = db.execute_insert(query)   # Returns last_insert_id
```

### UPDATE

```ruby
query = db.update('users')
  .set(status: 'active')
  .where('id', 1)

affected = db.execute_update(query)  # Returns affected_rows
```

### DELETE

```ruby
query = db.delete('users')
  .where('status', 'banned')

affected = db.execute_delete(query)  # Returns affected_rows
```

### Raw SQL

```ruby
results = db.raw('SELECT * FROM users WHERE age > ?', 18)
db.raw('UPDATE users SET views = views + 1 WHERE id = ?', 5)
```

### Transactions

```ruby
db.transaction do
  db.execute_insert(...)
  db.execute_update(...)
  # Commits on success, rolls back on error
end
```

## Example

See `examples/demo.rb` for a complete demonstration of all features.

## Documentation

- [Query Builder](query-builder.md)
- [Advanced Features](advanced-features.md)
- [API Reference](api-reference.md)
