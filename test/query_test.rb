# frozen_string_literal: true

require_relative 'test_helper'

class QueryTest < Minitest::Test
  def test_basic_select
    query = Quby::Query.new('users')
    assert_equal 'SELECT * FROM users', query.to_sql
    assert_empty query.bindings
  end

  def test_select_specific_columns
    query = Quby::Query.new('users').select('id', 'name', 'email')
    assert_equal 'SELECT id, name, email FROM users', query.to_sql
  end

  def test_select_with_distinct
    query = Quby::Query.new('users').select('country').distinct
    assert_equal 'SELECT DISTINCT country FROM users', query.to_sql
  end

  def test_from_method
    query = Quby::Query.new.from('users')
    assert_equal 'SELECT * FROM users', query.to_sql
  end

  def test_where_basic
    query = Quby::Query.new('users').where('age', '>', 18)
    assert_equal 'SELECT * FROM users WHERE age > ?', query.to_sql
    assert_equal [18], query.bindings
  end

  def test_where_default_operator
    query = Quby::Query.new('users').where('name', 'Alice')
    assert_equal 'SELECT * FROM users WHERE name = ?', query.to_sql
    assert_equal ['Alice'], query.bindings
  end

  def test_where_hash
    query = Quby::Query.new('users').where(name: 'Alice', age: 28)
    assert_equal 'SELECT * FROM users WHERE name = ? AND age = ?', query.to_sql
    assert_equal ['Alice', 28], query.bindings
  end

  def test_multiple_where
    query = Quby::Query.new('users')
      .where('age', '>', 18)
      .where('country', 'USA')
    assert_equal 'SELECT * FROM users WHERE age > ? AND country = ?', query.to_sql
    assert_equal [18, 'USA'], query.bindings
  end

  def test_or_where
    query = Quby::Query.new('users')
      .where('age', '>', 30)
      .or_where('status', 'premium')
    assert_equal 'SELECT * FROM users WHERE age > ? OR status = ?', query.to_sql
    assert_equal [30, 'premium'], query.bindings
  end

  def test_where_in
    query = Quby::Query.new('users').where_in('id', [1, 2, 3])
    assert_equal 'SELECT * FROM users WHERE id IN (?, ?, ?)', query.to_sql
    assert_equal [1, 2, 3], query.bindings
  end

  def test_where_not_in
    query = Quby::Query.new('users').where_not_in('status', ['banned', 'suspended'])
    assert_equal 'SELECT * FROM users WHERE status NOT IN (?, ?)', query.to_sql
    assert_equal ['banned', 'suspended'], query.bindings
  end

  def test_where_null
    query = Quby::Query.new('users').where_null('deleted_at')
    assert_equal 'SELECT * FROM users WHERE deleted_at IS NULL', query.to_sql
    assert_empty query.bindings
  end

  def test_where_not_null
    query = Quby::Query.new('users').where_not_null('email')
    assert_equal 'SELECT * FROM users WHERE email IS NOT NULL', query.to_sql
    assert_empty query.bindings
  end

  def test_where_between
    query = Quby::Query.new('products').where_between('price', 10, 100)
    assert_equal 'SELECT * FROM products WHERE price BETWEEN ? AND ?', query.to_sql
    assert_equal [10, 100], query.bindings
  end

  def test_where_raw
    query = Quby::Query.new('users').where_raw('YEAR(created_at) = ?', 2024)
    assert_equal 'SELECT * FROM users WHERE YEAR(created_at) = ?', query.to_sql
    assert_equal [2024], query.bindings
  end

  def test_join
    query = Quby::Query.new('orders')
      .select('orders.*', 'users.name')
      .join('users', 'orders.user_id', '=', 'users.id')
    expected = 'SELECT orders.*, users.name FROM orders INNER JOIN users ON orders.user_id = users.id'
    assert_equal expected, query.to_sql
  end

  def test_left_join
    query = Quby::Query.new('users')
      .left_join('profiles', 'users.id', '=', 'profiles.user_id')
    expected = 'SELECT * FROM users LEFT JOIN profiles ON users.id = profiles.user_id'
    assert_equal expected, query.to_sql
  end

  def test_right_join
    query = Quby::Query.new('users')
      .right_join('addresses', 'users.id', '=', 'addresses.user_id')
    expected = 'SELECT * FROM users RIGHT JOIN addresses ON users.id = addresses.user_id'
    assert_equal expected, query.to_sql
  end

  def test_order_by
    query = Quby::Query.new('users').order_by('name', 'ASC')
    assert_equal 'SELECT * FROM users ORDER BY name ASC', query.to_sql
  end

  def test_order_by_desc
    query = Quby::Query.new('users').order_by_desc('created_at')
    assert_equal 'SELECT * FROM users ORDER BY created_at DESC', query.to_sql
  end

  def test_multiple_order_by
    query = Quby::Query.new('users')
      .order_by('country', 'ASC')
      .order_by_desc('age')
    assert_equal 'SELECT * FROM users ORDER BY country ASC, age DESC', query.to_sql
  end

  def test_group_by
    query = Quby::Query.new('orders')
      .select('user_id', 'COUNT(*) as count')
      .group_by('user_id')
    assert_equal 'SELECT user_id, COUNT(*) as count FROM orders GROUP BY user_id', query.to_sql
  end

  def test_group_by_multiple
    query = Quby::Query.new('orders').group_by('country', 'city')
    assert_equal 'SELECT * FROM orders GROUP BY country, city', query.to_sql
  end

  def test_having
    query = Quby::Query.new('orders')
      .select('user_id', 'COUNT(*) as count')
      .group_by('user_id')
      .having('count', '>', 5)
    expected = 'SELECT user_id, COUNT(*) as count FROM orders GROUP BY user_id HAVING count > ?'
    assert_equal expected, query.to_sql
    assert_equal [5], query.bindings
  end

  def test_limit
    query = Quby::Query.new('users').limit(10)
    assert_equal 'SELECT * FROM users LIMIT 10', query.to_sql
  end

  def test_offset
    query = Quby::Query.new('users').limit(10).offset(20)
    assert_equal 'SELECT * FROM users LIMIT 10 OFFSET 20', query.to_sql
  end

  def test_take_and_skip
    query = Quby::Query.new('users').take(5).skip(10)
    assert_equal 'SELECT * FROM users LIMIT 5 OFFSET 10', query.to_sql
  end

  def test_page
    query = Quby::Query.new('users').page(3, 15)
    assert_equal 'SELECT * FROM users LIMIT 15 OFFSET 30', query.to_sql
  end

  def test_complex_query
    query = Quby::Query.new('orders')
      .select('orders.id', 'users.name', 'COUNT(items.id) as item_count')
      .join('users', 'orders.user_id', '=', 'users.id')
      .join('items', 'orders.id', '=', 'items.order_id')
      .where('orders.status', 'completed')
      .where('orders.total', '>', 100)
      .group_by('orders.id', 'users.name')
      .having('item_count', '>', 1)
      .order_by('orders.total', 'DESC')
      .limit(50)

    expected = 'SELECT orders.id, users.name, COUNT(items.id) as item_count FROM orders ' \
               'INNER JOIN users ON orders.user_id = users.id ' \
               'INNER JOIN items ON orders.id = items.order_id ' \
               'WHERE orders.status = ? AND orders.total > ? ' \
               'GROUP BY orders.id, users.name ' \
               'HAVING item_count > ? ' \
               'ORDER BY orders.total DESC ' \
               'LIMIT 50'
    
    assert_equal expected, query.to_sql
    assert_equal ['completed', 100, 1], query.bindings
  end

  def test_chaining_returns_self
    query = Quby::Query.new('users')
    assert_same query, query.select('id')
    assert_same query, query.where('age', '>', 18)
    assert_same query, query.order_by('name')
    assert_same query, query.limit(10)
  end

  def test_no_table_raises_error
    query = Quby::Query.new
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No table specified', error.message
  end
end
