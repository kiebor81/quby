# frozen_string_literal: true

# Setup SimpleCov before loading any application code
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/examples/'
  add_group 'Core', 'lib/quby.rb'
  add_group 'Query Builders', 'lib/quby/*_query.rb'
  add_group 'Connection', 'lib/quby/connection.rb'
  add_group 'Repository', 'lib/quby/repository.rb'
  add_group 'Configuration', 'lib/quby/configuration.rb'
  add_group 'Adapters', 'lib/quby/adapters'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'quby'

require 'minitest/autorun'
require 'minitest/reporters'

# Use beautiful test output
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new(color: true)
]

# Test helper for setting up in-memory SQLite database
module TestHelper
  def setup_db
    @db = Quby.connect(:sqlite, ':memory:')
    create_test_schema
  end

  def create_test_schema
    @db.raw(<<-SQL)
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER,
        country TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT
      )
    SQL

    @db.raw(<<-SQL)
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        content TEXT,
        published BOOLEAN DEFAULT 0,
        views INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    SQL
  end

  def seed_users
    @db.execute_insert(
      @db.insert('users').values([
        { name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA', status: 'active' },
        { name: 'Bob', email: 'bob@example.com', age: 35, country: 'UK', status: 'active' },
        { name: 'Charlie', email: 'charlie@example.com', age: 42, country: 'USA', status: 'premium' }
      ])
    )
  end

  def seed_posts
    @db.execute_insert(
      @db.insert('posts').values([
        { user_id: 1, title: 'First Post', content: 'Content 1', published: 1, views: 100 },
        { user_id: 1, title: 'Second Post', content: 'Content 2', published: 1, views: 50 },
        { user_id: 2, title: 'Third Post', content: 'Content 3', published: 0, views: 10 }
      ])
    )
  end
end
