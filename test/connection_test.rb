# frozen_string_literal: true

require_relative 'test_helper'

class ConnectionTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
  end

  def test_query_factory_method
    query = @db.query('users')
    assert_instance_of Quby::Query, query
    assert_equal 'users', query.table
  end

  def test_from_factory_method
    query = @db.from('users')
    assert_instance_of Quby::Query, query
    assert_equal 'users', query.table
  end

  def test_table_factory_method
    query = @db.table('users')
    assert_instance_of Quby::Query, query
    assert_equal 'users', query.table
  end

  def test_insert_factory_method
    query = @db.insert('users')
    assert_instance_of Quby::InsertQuery, query
    assert_equal 'users', query.table
  end

  def test_update_factory_method
    query = @db.update('users')
    assert_instance_of Quby::UpdateQuery, query
    assert_equal 'users', query.table
  end

  def test_delete_factory_method
    query = @db.delete('users')
    assert_instance_of Quby::DeleteQuery, query
    assert_equal 'users', query.table
  end

  def test_get_executes_query
    seed_users
    
    results = @db.get(@db.query('users').where('age', '>', 30))
    
    assert_equal 2, results.length
    assert_equal 'Bob', results[0]['name']
    assert_equal 'Charlie', results[1]['name']
  end

  def test_first_returns_single_result
    seed_users
    
    result = @db.first(@db.query('users').order_by('age', 'ASC'))
    
    assert_equal 'Alice', result['name']
    assert_equal 28, result['age']
  end

  def test_execute_insert
    query = @db.insert('users').values(
      name: 'Dave',
      email: 'dave@example.com',
      age: 45,
      country: 'Canada'
    )
    
    @db.execute_insert(query)
    
    results = @db.get(@db.query('users').where('name', 'Dave'))
    assert_equal 1, results.length
    assert_equal 'dave@example.com', results[0]['email']
  end

  def test_execute_update
    seed_users
    
    query = @db.update('users')
      .set(status: 'inactive')
      .where('email', 'alice@example.com')
    
    @db.execute_update(query)
    
    result = @db.first(@db.query('users').where('email', 'alice@example.com'))
    assert_equal 'inactive', result['status']
  end

  def test_execute_delete
    seed_users
    
    query = @db.delete('users').where('age', '<', 30)
    @db.execute_delete(query)
    
    results = @db.get(@db.query('users'))
    assert_equal 2, results.length
    refute results.any? { |r| r['age'] < 30 }
  end

  def test_raw_sql
    seed_users
    
    results = @db.raw('SELECT name, age FROM users WHERE country = ? ORDER BY age DESC', 'USA')
    
    assert_equal 2, results.length
    assert_equal 'Charlie', results[0]['name']
    assert_equal 42, results[0]['age']
  end

  def test_transaction_commits_on_success
    @db.transaction do
      @db.execute_insert(@db.insert('users').values(
        name: 'Alice',
        email: 'alice@example.com',
        age: 28,
        country: 'USA'
      ))
    end
    
    results = @db.get(@db.query('users'))
    assert_equal 1, results.length
  end

  def test_transaction_rolls_back_on_error
    begin
      @db.transaction do
        @db.execute_insert(@db.insert('users').values(
          name: 'Alice',
          email: 'alice@example.com',
          age: 28,
          country: 'USA'
        ))
        
        raise 'Intentional error'
      end
    rescue => e
      # Expected error
    end
    
    results = @db.get(@db.query('users'))
    assert_equal 0, results.length
  end

  def test_complex_query_with_joins
    seed_users
    seed_posts
    
    query = @db.query('posts')
      .select('posts.title', 'users.name as author')
      .join('users', 'posts.user_id', '=', 'users.id')
      .where('posts.published', 1)
      .order_by('posts.views', 'DESC')
    
    results = @db.get(query)
    
    assert_equal 2, results.length
    assert_equal 'First Post', results[0]['title']
    assert_equal 'Alice', results[0]['author']
  end
end
