# frozen_string_literal: true

require_relative 'test_helper'

class ReturnValuesTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
  end

  def test_insert_returns_last_insert_id
    id = @db.execute_insert(
      @db.insert('users').values(
        name: 'Alice',
        email: 'alice@example.com',
        age: 28,
        country: 'USA'
      )
    )
    
    assert_instance_of Integer, id
    assert_equal 1, id
  end

  def test_sequential_inserts_return_incrementing_ids
    id1 = @db.execute_insert(
      @db.insert('users').values(name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA')
    )
    
    id2 = @db.execute_insert(
      @db.insert('users').values(name: 'Bob', email: 'bob@example.com', age: 35, country: 'UK')
    )
    
    id3 = @db.execute_insert(
      @db.insert('users').values(name: 'Charlie', email: 'charlie@example.com', age: 42, country: 'USA')
    )
    
    assert_equal 1, id1
    assert_equal 2, id2
    assert_equal 3, id3
  end

  def test_bulk_insert_returns_last_insert_id
    id = @db.execute_insert(
      @db.insert('users').values([
        { name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA' },
        { name: 'Bob', email: 'bob@example.com', age: 35, country: 'UK' },
        { name: 'Charlie', email: 'charlie@example.com', age: 42, country: 'USA' }
      ])
    )
    
    assert_instance_of Integer, id
    assert_equal 3, id # Last inserted row
  end

  def test_update_returns_affected_rows
    seed_users
    
    affected = @db.execute_update(
      @db.update('users')
        .set(status: 'premium')
        .where('email', 'alice@example.com')
    )
    
    assert_instance_of Integer, affected
    assert_equal 1, affected
  end

  def test_update_multiple_rows_returns_count
    seed_users
    
    affected = @db.execute_update(
      @db.update('users')
        .set(status: 'verified')
        .where('age', '>', 30)
    )
    
    assert_equal 2, affected # Bob and Charlie
  end

  def test_update_no_matches_returns_zero
    seed_users
    
    affected = @db.execute_update(
      @db.update('users')
        .set(status: 'banned')
        .where('id', 999)
    )
    
    assert_equal 0, affected
  end

  def test_delete_returns_affected_rows
    seed_users
    
    affected = @db.execute_delete(
      @db.delete('users').where('email', 'alice@example.com')
    )
    
    assert_instance_of Integer, affected
    assert_equal 1, affected
  end

  def test_delete_multiple_rows_returns_count
    seed_users
    
    affected = @db.execute_delete(
      @db.delete('users').where('country', 'USA')
    )
    
    assert_equal 2, affected # Alice and Charlie
  end

  def test_delete_no_matches_returns_zero
    seed_users
    
    affected = @db.execute_delete(
      @db.delete('users').where('id', 999)
    )
    
    assert_equal 0, affected
  end

  def test_delete_all_returns_total_count
    seed_users
    
    affected = @db.execute_delete(@db.delete('users'))
    
    assert_equal 3, affected
  end

  def test_insert_use_returned_id_in_subsequent_query
    user_id = @db.execute_insert(
      @db.insert('users').values(
        name: 'Alice',
        email: 'alice@example.com',
        age: 28,
        country: 'USA'
      )
    )
    
    # Use the returned ID to insert a post
    post_id = @db.execute_insert(
      @db.insert('posts').values(
        user_id: user_id,
        title: 'First Post',
        content: 'Hello World',
        published: 1
      )
    )
    
    assert_equal 1, user_id
    assert_equal 1, post_id
    
    # Verify the relationship
    post = @db.first(@db.query('posts').where('id', post_id))
    assert_equal user_id, post['user_id']
  end

  def test_update_returns_can_be_used_for_validation
    seed_users
    
    # Update existing user
    affected = @db.execute_update(
      @db.update('users')
        .set(name: 'Alice Updated')
        .where('email', 'alice@example.com')
    )
    assert affected > 0, "Update should affect at least one row"
    
    # Try to update non-existent user
    affected = @db.execute_update(
      @db.update('users')
        .set(name: 'Nobody')
        .where('email', 'nonexistent@example.com')
    )
    assert_equal 0, affected, "Update should not affect any rows"
  end
end
