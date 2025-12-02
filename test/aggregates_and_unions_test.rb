# frozen_string_literal: true

require_relative 'test_helper'

class AggregatesAndUnionsTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
  end

  # Aggregate shortcuts
  def test_count_aggregate
    query = @db.query('users').count
    assert_equal 'SELECT COUNT(*) as count FROM users', query.to_sql
  end

  def test_count_with_column
    query = @db.query('users').count('DISTINCT country')
    assert_equal 'SELECT COUNT(DISTINCT country) as count FROM users', query.to_sql
  end

  def test_avg_aggregate
    query = @db.query('users').avg('age')
    assert_equal 'SELECT AVG(age) as avg FROM users', query.to_sql
  end

  def test_sum_aggregate
    query = @db.query('users').sum('salary')
    assert_equal 'SELECT SUM(salary) as sum FROM users', query.to_sql
  end

  def test_min_aggregate
    query = @db.query('users').min('age')
    assert_equal 'SELECT MIN(age) as min FROM users', query.to_sql
  end

  def test_max_aggregate
    query = @db.query('users').max('age')
    assert_equal 'SELECT MAX(age) as max FROM users', query.to_sql
  end

  def test_aggregate_with_where
    query = @db.query('users').where('active', true).count
    assert_equal 'SELECT COUNT(*) as count FROM users WHERE active = ?', query.to_sql
    assert_equal [true], query.bindings
  end

  def test_aggregate_execution
    # Insert test data
    @db.execute_insert(@db.insert('users').values([
      { name: 'Alice', email: 'alice@test.com', age: 28 },
      { name: 'Bob', email: 'bob@test.com', age: 35 },
      { name: 'Carol', email: 'carol@test.com', age: 22 }
    ]))

    result = @db.first(@db.query('users').count)
    assert_equal 3, result['count']

    result = @db.first(@db.query('users').avg('age'))
    assert_in_delta 28.33, result['avg'], 0.1

    result = @db.first(@db.query('users').sum('age'))
    assert_equal 85, result['sum']

    result = @db.first(@db.query('users').min('age'))
    assert_equal 22, result['min']

    result = @db.first(@db.query('users').max('age'))
    assert_equal 35, result['max']
  end

  # WHERE EXISTS / NOT EXISTS
  def test_where_exists_with_string
    query = @db.query('users')
      .where_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
    
    assert_equal 'SELECT * FROM users WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)', query.to_sql
  end

  def test_where_exists_with_query
    subquery = @db.query('orders')
      .select('1')
      .where_raw('orders.user_id = users.id')
    
    query = @db.query('users').where_exists(subquery)
    
    assert_includes query.to_sql, 'EXISTS (SELECT 1 FROM orders'
    assert_includes query.to_sql, 'orders.user_id = users.id'
  end

  def test_where_not_exists
    query = @db.query('users')
      .where_not_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
    
    assert_equal 'SELECT * FROM users WHERE NOT EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)', query.to_sql
  end

  def test_where_exists_execution
    # Create orders table
    @db.raw('CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER, total INTEGER)')
    
    # Insert data
    @db.execute_insert(@db.insert('users').values([
      { name: 'Alice', email: 'alice@test.com', age: 28 },
      { name: 'Bob', email: 'bob@test.com', age: 35 }
    ]))
    
    @db.execute_insert(@db.insert('orders').values(user_id: 1, total: 100))
    
    # Users with orders
    query = @db.query('users')
      .where_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
    
    results = @db.get(query)
    assert_equal 1, results.length
    assert_equal 'Alice', results.first['name']
    
    # Users without orders
    query = @db.query('users')
      .where_not_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
    
    results = @db.get(query)
    assert_equal 1, results.length
    assert_equal 'Bob', results.first['name']
  end

  # CROSS JOIN
  def test_cross_join
    query = @db.query('users').cross_join('departments')
    assert_equal 'SELECT * FROM users CROSS JOIN departments', query.to_sql
  end

  def test_cross_join_with_where
    query = @db.query('users')
      .cross_join('departments')
      .where('users.active', true)
    
    assert_equal 'SELECT * FROM users CROSS JOIN departments WHERE users.active = ?', query.to_sql
    assert_equal [true], query.bindings
  end

  def test_cross_join_execution
    @db.raw('CREATE TABLE sizes (size TEXT)')
    @db.raw('CREATE TABLE colors (color TEXT)')
    
    @db.execute_insert(@db.insert('sizes').values([{ size: 'S' }, { size: 'M' }]))
    @db.execute_insert(@db.insert('colors').values([{ color: 'Red' }, { color: 'Blue' }]))
    
    query = @db.query('sizes').cross_join('colors')
    results = @db.get(query)
    
    assert_equal 4, results.length  # 2 sizes × 2 colors
  end

  # UNION / UNION ALL
  def test_union
    query1 = @db.query('users').select('name').where('age', '>', 30)
    query2 = @db.query('users').select('name').where('country', 'USA')
    
    query = query1.union(query2)
    
    assert_includes query.to_sql, 'UNION SELECT'
    assert_includes query.to_sql, 'age > ?'
    assert_includes query.to_sql, 'country = ?'
  end

  def test_union_all
    query1 = @db.query('active_users').select('id', 'name')
    query2 = @db.query('inactive_users').select('id', 'name')
    
    query = query1.union_all(query2)
    
    assert_includes query.to_sql, 'UNION ALL SELECT'
  end

  def test_union_execution
    @db.execute_insert(@db.insert('users').values([
      { name: 'Alice', email: 'alice@test.com', age: 28, country: 'USA' },
      { name: 'Bob', email: 'bob@test.com', age: 35, country: 'UK' },
      { name: 'Carol', email: 'carol@test.com', age: 32, country: 'USA' }
    ]))
    
    query1 = @db.query('users').select('name').where('age', '>', 30)
    query2 = @db.query('users').select('name').where('country', 'USA')
    
    results = @db.get(query1.union(query2))
    
    # UNION removes duplicates, so we should get unique names
    names = results.map { |r| r['name'] }.sort
    assert_includes names, 'Alice'
    assert_includes names, 'Bob'
    assert_includes names, 'Carol'
  end

  def test_union_all_execution
    @db.execute_insert(@db.insert('users').values([
      { name: 'Alice', email: 'alice@test.com', age: 35, country: 'USA' },
      { name: 'Bob', email: 'bob@test.com', age: 25, country: 'USA' }
    ]))
    
    query1 = @db.query('users').select('name').where('age', '>', 30)
    query2 = @db.query('users').select('name').where('country', 'USA')
    
    results = @db.get(query1.union_all(query2))
    
    # UNION ALL keeps duplicates
    assert_equal 3, results.length  # Alice appears twice
  end

  def test_multiple_unions
    query1 = @db.query('users').select('name').where('age', '<', 25)
    query2 = @db.query('users').select('name').where('age', 'BETWEEN', [25, 35])
    query3 = @db.query('users').select('name').where('age', '>', 35)
    
    query = query1.union(query2).union(query3)
    
    sql = query.to_sql
    assert_equal 2, sql.scan(/UNION/).length
  end

  # Combined features
  def test_aggregate_with_exists
    query = @db.query('users')
      .count
      .where_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
    
    assert_includes query.to_sql, 'COUNT(*) as count'
    assert_includes query.to_sql, 'EXISTS'
  end

  def test_cross_join_with_aggregates
    query = @db.query('products')
      .select('products.category', 'COUNT(*) as total')
      .cross_join('stores')
      .group_by('products.category')
    
    assert_includes query.to_sql, 'CROSS JOIN stores'
    assert_includes query.to_sql, 'GROUP BY products.category'
  end
end
