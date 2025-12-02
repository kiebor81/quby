# frozen_string_literal: true

require_relative 'test_helper'

class InsertQueryTest < Minitest::Test
  def test_single_insert
    query = Quby::InsertQuery.new('users').values(
      name: 'Alice',
      email: 'alice@example.com',
      age: 28
    )
    
    assert_equal 'INSERT INTO users (name, email, age) VALUES (?, ?, ?)', query.to_sql
    assert_equal ['Alice', 'alice@example.com', 28], query.bindings
  end

  def test_bulk_insert
    query = Quby::InsertQuery.new('users').values([
      { name: 'Alice', email: 'alice@example.com', age: 28 },
      { name: 'Bob', email: 'bob@example.com', age: 35 },
      { name: 'Charlie', email: 'charlie@example.com', age: 42 }
    ])

    expected = 'INSERT INTO users (name, email, age) VALUES (?, ?, ?), (?, ?, ?), (?, ?, ?)'
    assert_equal expected, query.to_sql
    assert_equal ['Alice', 'alice@example.com', 28, 'Bob', 'bob@example.com', 35, 'Charlie', 'charlie@example.com', 42], query.bindings
  end

  def test_into_method
    query = Quby::InsertQuery.new.into('users').values(name: 'Alice', email: 'alice@example.com')
    assert_equal 'INSERT INTO users (name, email) VALUES (?, ?)', query.to_sql
  end

  def test_no_table_raises_error
    query = Quby::InsertQuery.new
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No table specified', error.message
  end

  def test_no_values_raises_error
    query = Quby::InsertQuery.new('users')
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No values specified', error.message
  end
end
