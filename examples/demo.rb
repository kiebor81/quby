# frozen_string_literal: true

require_relative '../lib/quby'

puts "=" * 70
puts "QUBY - Query Builder Demo"
puts "=" * 70
puts

# Setup database
db_file = 'demo.db'
File.delete(db_file) if File.exist?(db_file)

# Configure globally
Quby.setup(:sqlite, database: db_file)
db = Quby.connection

# Create schema
db.raw(<<~SQL)
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    age INTEGER,
    country TEXT,
    status TEXT DEFAULT 'active'
  )
SQL

db.raw(<<~SQL)
  CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT NOT NULL,
    content TEXT,
    created_at TEXT
  )
SQL

puts "Database setup complete\n\n"

# ============================================================================
# 1. QUERY BUILDER - SELECT
# ============================================================================
puts "1. QUERY BUILDER - SELECT"
puts "-" * 70

# Insert test data
db.execute_insert(db.insert('users').values([
  { name: 'Alice Johnson', email: 'alice@example.com', age: 28, country: 'USA' },
  { name: 'Bob Smith', email: 'bob@example.com', age: 35, country: 'UK' },
  { name: 'Carol White', email: 'carol@example.com', age: 22, country: 'USA' },
  { name: 'David Brown', email: 'david@example.com', age: 45, country: 'Canada' }
]))

# Basic SELECT
users = db.get(db.query('users').select('name', 'age').limit(2))
puts "Basic SELECT (first 2): #{users.map { |u| u['name'] }.join(', ')}"

# WHERE with operators
usa_users = db.get(db.query('users').where('country', 'USA'))
puts "WHERE country = 'USA': #{usa_users.length} users"

adults = db.get(db.query('users').where('age', '>=', 25))
puts "WHERE age >= 25: #{adults.length} users"

# ORDER BY
ordered = db.get(db.query('users').order_by('age', 'DESC').limit(1))
puts "Oldest user: #{ordered.first['name']} (#{ordered.first['age']} years old)"

# Aggregates
result = db.first(db.query('users').select('COUNT(*) as total, AVG(age) as avg_age'))
puts "Total users: #{result['total']}, Average age: #{result['avg_age'].round(1)}\n\n"

# ============================================================================
# 2. INSERT / UPDATE / DELETE
# ============================================================================
puts "2. INSERT / UPDATE / DELETE"
puts "-" * 70

# INSERT returns ID
new_id = db.execute_insert(
  db.insert('users').values(name: 'Eve Davis', email: 'eve@example.com', age: 30, country: 'USA')
)
puts "INSERT: Created user with ID #{new_id}"

# UPDATE returns affected rows
affected = db.execute_update(
  db.update('users').set(status: 'premium').where('country', 'USA')
)
puts "UPDATE: Set #{affected} users to premium status"

# DELETE returns affected rows
affected = db.execute_delete(
  db.delete('users').where('age', '<', 25)
)
puts "DELETE: Removed #{affected} users under age 25\n\n"

# ============================================================================
# 3. MODEL MAPPING (Dapper-style)
# ============================================================================
puts "3. MODEL MAPPING"
puts "-" * 70

class User
  attr_accessor :id, :name, :email, :age, :country, :status
  
  def initialize(attributes = {})
    attributes.each { |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
  end
  
  def display
    "#{name} (#{age}) from #{country}"
  end
end

# Query returns User objects instead of hashes
users = db.get(db.query('users').order_by('name'), User)
puts "Mapped to User objects:"
users.each { |user| puts "  - #{user.display}" }
puts

# ============================================================================
# 4. REPOSITORY PATTERN
# ============================================================================
puts "4. REPOSITORY PATTERN"
puts "-" * 70

class UserRepository < Quby::Repository
  table 'users'
  model User
  
  # Custom finder
  def find_by_email(email)
    find_by('email', email)
  end
  
  # Custom query
  def premium_users
    where('status', 'premium')
  end
end

repo = UserRepository.new  # Uses global Quby.connection

# CRUD operations
user = repo.find(1)
puts "Find by ID: #{user.name}" if user

user = repo.find_by_email('bob@example.com')
puts "Find by email: #{user.name}" if user

premium = repo.premium_users
puts "Premium users: #{premium.map(&:name).join(', ')}"

count = repo.count
puts "Total users: #{count}\n\n"

# ============================================================================
# 5. TRANSACTIONS
# ============================================================================
puts "5. TRANSACTIONS"
puts "-" * 70

# Successful transaction
db.transaction do
  user_id = db.execute_insert(
    db.insert('users').values(name: 'Frank Wilson', email: 'frank@example.com', age: 40, country: 'USA')
  )
  
  db.execute_insert(
    db.insert('posts').values(
      user_id: user_id,
      title: 'My First Post',
      content: 'Hello, Quby!',
      created_at: Time.now.to_s
    )
  )
end
puts "Transaction committed: User and post created"

# Failed transaction (rollback)
begin
  db.transaction do
    db.execute_insert(
      db.insert('users').values(name: 'Invalid', email: 'invalid@example.com', age: 99, country: 'Test')
    )
    raise StandardError, "Simulated error"
  end
rescue StandardError => e
  puts "Transaction rolled back: #{e.message}"
end
puts

# ============================================================================
# 6. RAW SQL
# ============================================================================
puts "6. RAW SQL"
puts "-" * 70

# Raw query with bindings
results = db.raw('SELECT name, age FROM users WHERE country = ? ORDER BY age DESC', 'USA')
puts "Raw SQL results:"
results.each { |row| puts "  - #{row['name']} (#{row['age']})" }
puts

# ============================================================================
# 7. ADVANCED QUERIES
# ============================================================================
puts "7. ADVANCED QUERIES"
puts "-" * 70

# JOIN
results = db.get(
  db.query('posts')
    .select('posts.title', 'users.name as author')
    .join('users', 'posts.user_id', '=', 'users.id')
)
puts "Posts with authors:"
results.each { |row| puts "  - '#{row['title']}' by #{row['author']}" }
puts

# WHERE IN
usa_uk_users = db.get(
  db.query('users').where_in('country', ['USA', 'UK']).select('name', 'country')
)
puts "Users from USA or UK: #{usa_uk_users.map { |u| u['name'] }.join(', ')}"

# Pagination
page1 = db.get(db.query('users').order_by('name').page(1, 3))
puts "Page 1 (3 per page): #{page1.map { |u| u['name'] }.join(', ')}\n\n"

# ============================================================================
# 8. NEW FEATURES
# ============================================================================
puts "8. NEW FEATURES (v1.0)"
puts "-" * 70

# Aggregate shortcuts
total_users = db.execute_scalar(db.query('users').count)
avg_age = db.execute_scalar(db.query('users').avg('age'))
puts "Aggregate shortcuts: #{total_users} users, average age: #{avg_age.round(1)}"

# WHERE EXISTS
subquery = db.query('posts').select('1').where_raw('posts.user_id = users.id')
users_with_posts = db.get(db.query('users').select('name').where_exists(subquery))
puts "Users with posts (WHERE EXISTS): #{users_with_posts.map { |u| u['name'] }.join(', ')}"

# CROSS JOIN (create a categories table for demo)
db.raw('CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT)')
db.execute_insert(db.insert('categories').values([
  { name: 'Tech' },
  { name: 'Travel' }
]))

cross_results = db.get(
  db.query('users').select('users.name', 'categories.name as category')
    .cross_join('categories')
    .limit(4)
)
puts "Cross join (users × categories, first 4):"
cross_results.each { |row| puts "  - #{row['name']} × #{row['category']}" }

# UNION
active_query = db.query('users').select('name').where('status', 'premium')
other_query = db.query('users').select('name').where('country', 'UK')
combined = db.get(active_query.union(other_query))
puts "Union (premium OR UK users): #{combined.map { |u| u['name'] }.join(', ')}\n\n"

# ============================================================================
# CLEANUP
# ============================================================================
puts "=" * 70
puts "Demo complete! All features demonstrated."
puts "Run 'rm examples/demo.db' to clean up the database file."
puts "=" * 70
