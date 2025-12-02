# frozen_string_literal: true

require_relative 'test_helper'

# Test models
class TestUser
  attr_accessor :id, :name, :email, :age, :country, :status
  
  def initialize(attributes = {})
    attributes.each { |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
  end
end

class TestPost
  attr_accessor :id, :user_id, :title, :content, :published, :views
  
  def initialize(attributes = {})
    attributes.each { |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
  end
end

class TestProduct
  attr_accessor :id, :name, :price
  
  # No-arg constructor
  def initialize
  end
end

class ModelMappingTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
  end

  def test_get_returns_hashes_by_default
    seed_users
    
    results = @db.get(@db.query('users'))
    
    assert_instance_of Array, results
    assert_kind_of Hash, results.first
    assert_equal 'Alice', results.first['name']
  end

  def test_get_maps_to_model_class
    seed_users
    
    results = @db.get(@db.query('users'), TestUser)
    
    assert_instance_of Array, results
    assert_instance_of TestUser, results.first
    assert_equal 'Alice', results.first.name
    assert_equal 'alice@example.com', results.first.email
  end

  def test_get_maps_all_attributes
    seed_users
    
    user = @db.get(@db.query('users').where('name', 'Bob'), TestUser).first
    
    assert_equal 2, user.id
    assert_equal 'Bob', user.name
    assert_equal 'bob@example.com', user.email
    assert_equal 35, user.age
    assert_equal 'UK', user.country
    assert_equal 'active', user.status
  end

  def test_get_empty_result_returns_empty_array
    seed_users
    
    results = @db.get(@db.query('users').where('id', 999), TestUser)
    
    assert_instance_of Array, results
    assert_empty results
  end

  def test_first_returns_hash_by_default
    seed_users
    
    result = @db.first(@db.query('users').where('name', 'Alice'))
    
    assert_kind_of Hash, result
    assert_equal 'Alice', result['name']
  end

  def test_first_maps_to_model_class
    seed_users
    
    user = @db.first(@db.query('users').where('name', 'Alice'), TestUser)
    
    assert_instance_of TestUser, user
    assert_equal 'Alice', user.name
    assert_equal 28, user.age
  end

  def test_first_returns_nil_when_not_found
    seed_users
    
    user = @db.first(@db.query('users').where('id', 999), TestUser)
    
    assert_nil user
  end

  def test_first_with_model_returns_nil_not_empty_array
    seed_users
    
    user = @db.first(@db.query('users').where('email', 'nonexistent@example.com'), TestUser)
    
    assert_nil user
    refute_instance_of Array, user
  end

  def test_raw_sql_maps_to_model
    seed_users
    
    users = @db.raw('SELECT * FROM users WHERE age > ?', 30, model_class: TestUser)
    
    assert_instance_of Array, users
    assert users.all? { |u| u.is_a?(TestUser) }
    assert_equal 2, users.count
    assert users.all? { |u| u.age > 30 }
  end

  def test_raw_sql_without_model_class_returns_hashes
    seed_users
    
    users = @db.raw('SELECT * FROM users WHERE age > ?', 30)
    
    assert_instance_of Array, users
    assert_kind_of Hash, users.first
  end

  def test_maps_to_different_model_types
    seed_users
    seed_posts
    
    posts = @db.get(@db.query('posts').where('published', 1), TestPost)
    
    assert posts.all? { |p| p.is_a?(TestPost) }
    assert posts.first.title
    assert posts.first.user_id
  end

  def test_model_with_no_arg_constructor
    @db.raw('CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, price REAL)')
    @db.execute_insert(
      @db.insert('products').values([
        { name: 'Widget', price: 9.99 },
        { name: 'Gadget', price: 19.99 }
      ])
    )
    
    products = @db.get(@db.query('products'), TestProduct)
    
    assert_instance_of Array, products
    assert_instance_of TestProduct, products.first
    assert_equal 'Widget', products.first.name
    assert_equal 9.99, products.first.price
  end

  def test_ignores_extra_columns_not_in_model
    seed_users
    
    # Query with extra column
    query = @db.query('users')
      .select('users.*', "'extra_value' as extra_column")
      .where('id', 1)
    
    user = @db.first(query, TestUser)
    
    # Should not raise error, just ignore extra column
    assert_instance_of TestUser, user
    assert_equal 'Alice', user.name
    refute_respond_to user, :extra_column
  end

  def test_query_with_joins_maps_to_model
    seed_users
    seed_posts
    
    # Query posts with user info
    query = @db.query('posts')
      .select('posts.*')
      .join('users', 'posts.user_id', '=', 'users.id')
      .where('users.name', 'Alice')
    
    posts = @db.get(query, TestPost)
    
    assert posts.all? { |p| p.is_a?(TestPost) }
    assert_equal 2, posts.count
  end

  def test_model_mapping_preserves_data_types
    seed_users
    
    user = @db.first(@db.query('users').where('id', 1), TestUser)
    
    assert_instance_of Integer, user.id
    assert_instance_of String, user.name
    assert_instance_of Integer, user.age
  end

  def test_multiple_queries_with_different_models
    seed_users
    seed_posts
    
    users = @db.get(@db.query('users'), TestUser)
    posts = @db.get(@db.query('posts'), TestPost)
    
    assert users.all? { |u| u.is_a?(TestUser) }
    assert posts.all? { |p| p.is_a?(TestPost) }
    assert_equal 3, users.count
    assert_equal 3, posts.count
  end
end
