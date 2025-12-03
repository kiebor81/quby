# frozen_string_literal: true

require_relative '../lib/quby'
require_relative '../lib/quby/extensions/case_when'

# Enable the CASE WHEN extension using the plugin system
QueryKit.use_extensions(QueryKit::CaseWhenExtension)

# Setup database
db_file = 'case_demo.db'
File.delete(db_file) if File.exist?(db_file)

QueryKit.setup(:sqlite, database: db_file)
db = QueryKit.connection

# Create test table
db.raw(<<~SQL)
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    age INTEGER,
    status TEXT,
    score INTEGER
  )
SQL

# Insert test data
db.execute_insert(db.insert('users').values([
  { name: 'Alice', email: 'alice@example.com', age: 16, status: 'active', score: 95 },
  { name: 'Bob', email: 'bob@example.com', age: 25, status: 'active', score: 82 },
  { name: 'Carol', email: 'carol@example.com', age: 70, status: 'inactive', score: 78 },
  { name: 'David', email: 'david@example.com', age: 35, status: 'pending', score: 68 }
]))

puts "=" * 70
puts "CASE WHEN Extension Demo"
puts "=" * 70
puts

# Example 1: Simple CASE with column
puts "1. Simple CASE (with column)"
puts "-" * 70

case_expr = db.query('users')
  .select_case('status')
  .when('active').then('Active User')
  .when('inactive').then('Inactive User')
  .else('Pending User')
  .as('status_label')

query = db.query('users')
  .select('name', case_expr)

puts "SQL: #{query.to_sql}"
puts "Results:"
db.get(query).each { |row| puts "  #{row['name']}: #{row['status_label']}" }
puts

# Example 2: Searched CASE (age categories)
puts "2. Searched CASE (age categories)"
puts "-" * 70

case_expr = db.query('users')
  .select_case
  .when('age', '<', 18).then('Minor')
  .when('age', '<', 65).then('Adult')
  .else('Senior')
  .as('age_group')

query = db.query('users')
  .select('name', 'age', case_expr)

puts "SQL: #{query.to_sql}"
puts "Results:"
db.get(query).each { |row| puts "  #{row['name']} (#{row['age']}): #{row['age_group']}" }
puts

# Example 3: Grade calculation
puts "3. Grade calculation with CASE"
puts "-" * 70

case_expr = db.query('users')
  .select_case
  .when('score', '>=', 90).then('A')
  .when('score', '>=', 80).then('B')
  .when('score', '>=', 70).then('C')
  .else('F')
  .as('grade')

query = db.query('users')
  .select('name', 'score', case_expr)

puts "SQL: #{query.to_sql}"
puts "Results:"
db.get(query).each { |row| puts "  #{row['name']}: #{row['score']} -> #{row['grade']}" }
puts

# Example 4: Multiple CASE expressions
puts "4. Multiple CASE expressions in one query"
puts "-" * 70

age_case = db.query('users')
  .select_case
  .when('age', '<', 18).then('Young')
  .when('age', '<', 60).then('Middle')
  .else('Senior')
  .as('age_category')

status_case = db.query('users')
  .select_case('status')
  .when('active').then('Y')
  .else('N')
  .as('active_indicator')

query = db.query('users')
  .select('name', age_case, status_case)

puts "SQL: #{query.to_sql}"
puts "Results:"
db.get(query).each do |row|
  puts "  #{row['name']}: #{row['age_category']} | Active: #{row['active_indicator']}"
end
puts

# Example 5: CASE in WHERE clause (via raw)
puts "5. CASE with WHERE (using raw SQL)"
puts "-" * 70

results = db.raw(<<~SQL)
  SELECT name, age, status,
    CASE
      WHEN age < 18 THEN 'Minor'
      WHEN age < 65 THEN 'Adult'
      ELSE 'Senior'
    END as age_group
  FROM users
  WHERE 
    CASE status
      WHEN 'active' THEN 1
      ELSE 0
    END = 1
SQL

puts "Active users only with age groups:"
results.each { |row| puts "  #{row['name']}: #{row['age_group']}" }
puts

puts "=" * 70
puts "Demo complete! Run 'rm examples/case_demo.db' to clean up."
puts "=" * 70
