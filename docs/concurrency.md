# Concurrency and Thread Safety

## Overview

Quby provides thread-safe global configuration, but **database connections should not be shared across threads** in most cases. This guide explains how to safely use Quby in concurrent environments.

## Global Connection (`QueryKit.connection`)

### Thread-Safe Initialization

The global connection singleton is initialized in a thread-safe manner using a Mutex:

```ruby
QueryKit.setup(:sqlite, database: 'app.db')

# Safe: Multiple threads can call this simultaneously
threads = 10.times.map do
  Thread.new do
    db = QueryKit.connection  # Thread-safe singleton access
  end
end
threads.each(&:join)
```

### Shared Connection Limitations

While accessing the singleton is thread-safe, **using the same connection across threads is not recommended** because:

1. **SQLite**: Connections are not thread-safe and should not be shared
2. **PostgreSQL/MySQL**: While the drivers support connection sharing, it can lead to:
   - Transaction isolation issues
   - Connection state conflicts
   - Degraded performance due to serialization

## Recommended Patterns

### 1. Single-Threaded Applications

For single-threaded apps (most web requests, scripts), use the global connection:

```ruby
# Configure once at startup
QueryKit.setup(:sqlite, database: 'app.db')

# Use throughout the application
db = QueryKit.connection
users = db.get(db.query('users'))
```

### 2. Multi-Threaded Applications

For concurrent operations, create separate connections per thread:

```ruby
# DON'T: Share the global connection
threads = 10.times.map do
  Thread.new do
    db = QueryKit.connection  # ⚠️ All threads share same connection
    db.get(db.query('users'))
  end
end

# DO: Create separate connections per thread
threads = 10.times.map do
  Thread.new do
    db = QueryKit.connect(:sqlite, database: 'app.db')  # ✅ Each thread gets its own
    db.get(db.query('users'))
  end
end
threads.each(&:join)
```

### 3. Connection Pooling (Advanced)

For high-concurrency applications, implement a connection pool:

```ruby
require 'connection_pool'

# Create a pool of connections
DB_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  QueryKit.connect(:postgresql, 
    host: 'localhost',
    database: 'myapp',
    user: 'postgres',
    password: 'secret'
  )
end

# Use in threads
threads = 20.times.map do
  Thread.new do
    DB_POOL.with do |db|
      db.get(db.query('users'))
    end
  end
end
threads.each(&:join)
```

### 4. Thread-Local Connections

Store connections in thread-local storage:

```ruby
def db_connection
  Thread.current[:db] ||= QueryKit.connect(:sqlite, database: 'app.db')
end

threads = 10.times.map do
  Thread.new do
    db = db_connection  # Each thread gets its own connection
    db.get(db.query('users'))
  end
end
threads.each(&:join)
```

## Web Frameworks

### Rails

In Rails, each request runs in its own thread (or process with Puma/Unicorn). Create connections per-request:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :setup_db
  
  private
  
  def setup_db
    @db = QueryKit.connect(:postgresql,
      host: ENV['DB_HOST'],
      database: ENV['DB_NAME'],
      user: ENV['DB_USER'],
      password: ENV['DB_PASSWORD']
    )
  end
end
```

Or use a global connection (safe for Rails since each request has its own thread/process):

```ruby
# config/initializers/quby.rb
QueryKit.setup(:postgresql,
  host: ENV['DB_HOST'],
  database: ENV['DB_NAME'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASSWORD']
)

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @users = QueryKit.connection.get(
      QueryKit.connection.query('users')
    )
  end
end
```

### Sidekiq / Background Jobs

Create separate connections for background jobs:

```ruby
class UserImportJob
  include Sidekiq::Worker
  
  def perform(file_path)
    # Create a new connection for this job
    db = QueryKit.connect(:sqlite, database: 'app.db')
    
    # Process data...
    CSV.foreach(file_path) do |row|
      db.execute_insert(
        db.insert('users').values(name: row[0], email: row[1])
      )
    end
  end
end
```

## Transaction Isolation

Each thread should manage its own transactions:

```ruby
threads = 5.times.map do |i|
  Thread.new do
    db = QueryKit.connect(:postgresql, database: 'myapp')
    
    db.transaction do
      user = db.execute_insert(
        db.insert('users').values(name: "User #{i}")
      )
      
      db.execute_insert(
        db.insert('posts').values(user_id: user, title: "Post from thread #{i}")
      )
    end
  end
end
threads.each(&:join)
```

## Database-Specific Notes

### SQLite

- **Not thread-safe**: Each thread must have its own connection
- **Write serialization**: SQLite serializes writes, so concurrent writes will block
- **Read concurrency**: Multiple threads can read simultaneously with separate connections

```ruby
# Good for concurrent reads
readers = 10.times.map do
  Thread.new do
    db = QueryKit.connect(:sqlite, database: 'app.db')
    db.get(db.query('users'))
  end
end

# Writes will be serialized by SQLite
writers = 5.times.map do |i|
  Thread.new do
    db = QueryKit.connect(:sqlite, database: 'app.db')
    db.execute_insert(db.insert('users').values(name: "User #{i}"))
  end
end
```

### PostgreSQL

- **Connection pooling recommended**: Use pgBouncer or connection_pool gem
- **Transaction isolation**: Each connection has its own transaction state
- **Connection limit**: Default limit is 100 connections, plan accordingly

### MySQL

- **Thread-safe driver**: mysql2 gem is thread-safe
- **Connection pooling recommended**: Use connection_pool gem
- **Max connections**: Default is 151, adjust `max_connections` if needed

## Testing Concurrent Code

```ruby
require 'minitest/autorun'

class ConcurrencyTest < Minitest::Test
  def test_concurrent_reads
    db = QueryKit.connect(:sqlite, ':memory:')
    db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')
    db.execute_insert(db.insert('users').values(name: 'Alice'))
    
    threads = 10.times.map do
      Thread.new do
        # Each thread gets its own connection to the same in-memory database
        thread_db = QueryKit.connect(:sqlite, ':memory:')
        thread_db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')
        thread_db.get(thread_db.query('users'))
      end
    end
    
    results = threads.map(&:value)
    assert_equal 10, results.size
  end
end
```

## Summary

| Scenario | Recommendation | Pattern |
|----------|---------------|---------|
| Single-threaded script | Use `QueryKit.connection` | Global singleton |
| Multi-threaded app | Use `QueryKit.connect` per thread | Thread-local connections |
| Web framework (Rails) | Either works | Global or per-request |
| Background jobs | Use `QueryKit.connect` per job | Job-local connections |
| High concurrency | Use connection pooling | ConnectionPool gem |

## Key Takeaways

1. **Global configuration is thread-safe**
2. **Don't share connections across threads** (especially SQLite)
3. **Create separate connections with `QueryKit.connect` for concurrency**
4. **Use connection pooling for high-concurrency scenarios**
5. **Each thread should manage its own transactions**

For most applications, creating separate connections per thread/job is the simplest and safest approach.
