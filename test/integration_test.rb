# frozen_string_literal: true

require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
  end

  def test_full_crud_workflow
    # CREATE
    insert_query = @db.insert('users').values([
      { name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA', status: 'active' },
      { name: 'Bob', email: 'bob@example.com', age: 35, country: 'UK', status: 'active' },
      { name: 'Charlie', email: 'charlie@example.com', age: 42, country: 'USA', status: 'premium' }
    ])
    @db.execute_insert(insert_query)
    
    # READ
    all_users = @db.get(@db.query('users'))
    assert_equal 3, all_users.length
    
    # READ with filter
    usa_users = @db.get(@db.query('users').where('country', 'USA'))
    assert_equal 2, usa_users.length
    
    # READ first
    oldest = @db.first(@db.query('users').order_by_desc('age'))
    assert_equal 'Charlie', oldest['name']
    
    # UPDATE
    @db.execute_update(
      @db.update('users')
        .set(status: 'inactive')
        .where('email', 'alice@example.com')
    )
    
    alice = @db.first(@db.query('users').where('email', 'alice@example.com'))
    assert_equal 'inactive', alice['status']
    
    # DELETE
    @db.execute_delete(@db.delete('users').where('status', 'inactive'))
    
    remaining = @db.get(@db.query('users'))
    assert_equal 2, remaining.length
    refute remaining.any? { |u| u['status'] == 'inactive' }
  end

  def test_complex_reporting_query
    seed_users
    seed_posts
    
    # Get user post statistics
    query = @db.query('users')
      .select(
        'users.name',
        'users.country',
        'COUNT(posts.id) as post_count',
        'SUM(posts.views) as total_views',
        'AVG(posts.views) as avg_views'
      )
      .left_join('posts', 'users.id', '=', 'posts.user_id')
      .where('posts.published', 1)
      .group_by('users.id', 'users.name', 'users.country')
      .having('post_count', '>', 0)
      .order_by('total_views', 'DESC')
    
    results = @db.get(query)
    
    assert results.length > 0
    assert results[0]['post_count'] > 0
    assert results[0]['total_views'] > 0
  end

  def test_pagination_workflow
    # Insert test data
    users = (1..50).map do |i|
      { 
        name: "User#{i}", 
        email: "user#{i}@example.com", 
        age: 20 + (i % 30),
        country: 'USA'
      }
    end
    @db.execute_insert(@db.insert('users').values(users))
    
    # Page 1
    page1 = @db.get(@db.query('users').order_by('id', 'ASC').page(1, 10))
    assert_equal 10, page1.length
    assert_equal 'User1', page1[0]['name']
    
    # Page 2
    page2 = @db.get(@db.query('users').order_by('id', 'ASC').page(2, 10))
    assert_equal 10, page2.length
    assert_equal 'User11', page2[0]['name']
    
    # Page 5
    page5 = @db.get(@db.query('users').order_by('id', 'ASC').page(5, 10))
    assert_equal 10, page5.length
    assert_equal 'User41', page5[0]['name']
  end

  def test_transaction_with_multiple_operations
    result = @db.transaction do
      # Insert user
      @db.execute_insert(
        @db.insert('users').values(
          name: 'Alice',
          email: 'alice@example.com',
          age: 28,
          country: 'USA'
        )
      )
      
      # Get user ID (assuming auto-increment starts at 1)
      user = @db.first(@db.query('users').where('email', 'alice@example.com'))
      
      # Insert posts for the user
      @db.execute_insert(
        @db.insert('posts').values([
          { user_id: user['id'], title: 'First Post', content: 'Content 1', published: 1 },
          { user_id: user['id'], title: 'Second Post', content: 'Content 2', published: 1 }
        ])
      )
      
      user['id']
    end
    
    # Verify all operations committed
    users = @db.get(@db.query('users'))
    assert_equal 1, users.length
    
    posts = @db.get(@db.query('posts'))
    assert_equal 2, posts.length
    assert_equal result, posts[0]['user_id']
  end

  def test_bulk_operations
    # Bulk insert
    users = []
    100.times do |i|
      users << {
        name: "User#{i}",
        email: "user#{i}@example.com",
        age: 20 + (i % 50),
        country: i.even? ? 'USA' : 'UK'
      }
    end
    
    @db.execute_insert(@db.insert('users').values(users))
    
    # Bulk update
    @db.execute_update(
      @db.update('users')
        .set(status: 'verified')
        .where('country', 'USA')
    )
    
    # Verify
    verified = @db.get(@db.query('users').where('status', 'verified'))
    assert_equal 50, verified.length
    assert verified.all? { |u| u['country'] == 'USA' }
  end

  def test_where_in_with_subquery_pattern
    seed_users
    seed_posts
    
    # Get users who have published posts
    users_with_posts = @db.raw(
      'SELECT DISTINCT user_id FROM posts WHERE published = 1'
    ).map { |r| r['user_id'] }
    
    # Use WHERE IN with those user IDs
    query = @db.query('users').where_in('id', users_with_posts)
    results = @db.get(query)
    
    assert results.length > 0
    assert results.all? { |u| users_with_posts.include?(u['id']) }
  end

  def test_raw_sql_for_complex_queries
    seed_users
    
    # Use raw SQL for database-specific features
    results = @db.raw(<<-SQL, 30)
      SELECT 
        country,
        COUNT(*) as user_count,
        AVG(age) as avg_age,
        MIN(age) as youngest,
        MAX(age) as oldest
      FROM users
      WHERE age > ?
      GROUP BY country
      HAVING user_count > 0
      ORDER BY user_count DESC
    SQL
    
    assert results.length > 0
    assert results[0].key?('country')
    assert results[0].key?('user_count')
    assert results[0].key?('avg_age')
  end
end
