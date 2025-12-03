# frozen_string_literal: true

require_relative 'test_helper'

# Test models
class RepoTestUser
  attr_accessor :id, :name, :email, :age, :country, :status
  
  def initialize(attributes = {})
    attributes.each { |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
  end
end

class RepoTestPost
  attr_accessor :id, :user_id, :title, :content, :published, :views
  
  def initialize(attributes = {})
    attributes.each { |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
  end
end

# Test repositories
class TestUserRepo < QueryKit::Repository
  table 'users'
  model RepoTestUser
  
  def adults
    where('age', '>=', 18)
  end
end

class TestPostRepo < QueryKit::Repository
  table 'posts'
  model RepoTestPost
  
  def published
    where('published', 1)
  end
end

class RepositoryTest < Minitest::Test
  include TestHelper

  def setup
    setup_db
    @user_repo = TestUserRepo.new(@db)
    @post_repo = TestPostRepo.new(@db)
  end

  def test_repository_has_table_and_model_configured
    assert_equal 'users', TestUserRepo.table_name
    assert_equal RepoTestUser, TestUserRepo.model_class
  end

  def test_insert_returns_id
    id = @user_repo.insert(
      name: 'Test User',
      email: 'test@example.com',
      age: 30,
      country: 'USA'
    )
    
    assert_instance_of Integer, id
    assert_equal 1, id
  end

  def test_create_is_alias_for_insert
    id = @user_repo.create(name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA')
    
    assert_equal 1, id
  end

  def test_find_returns_model_instance
    seed_users
    
    user = @user_repo.find(1)
    
    assert_instance_of RepoTestUser, user
    assert_equal 'Alice', user.name
    assert_equal 'alice@example.com', user.email
  end

  def test_find_returns_nil_when_not_found
    seed_users
    
    user = @user_repo.find(999)
    
    assert_nil user
  end

  def test_find_by_returns_model_instance
    seed_users
    
    user = @user_repo.find_by('email', 'bob@example.com')
    
    assert_instance_of RepoTestUser, user
    assert_equal 'Bob', user.name
  end

  def test_all_returns_array_of_models
    seed_users
    
    users = @user_repo.all
    
    assert_instance_of Array, users
    assert_equal 3, users.count
    assert users.all? { |u| u.is_a?(RepoTestUser) }
  end

  def test_where_with_two_args
    seed_users
    
    users = @user_repo.where('country', 'USA')
    
    assert_equal 2, users.count
    assert users.all? { |u| u.country == 'USA' }
  end

  def test_where_with_three_args
    seed_users
    
    users = @user_repo.where('age', '>', 30)
    
    assert_equal 2, users.count
    assert users.all? { |u| u.age > 30 }
  end

  def test_where_in
    seed_users
    
    users = @user_repo.where_in('id', [1, 3])
    
    assert_equal 2, users.count
    assert_equal [1, 3], users.map(&:id).sort
  end

  def test_where_not_in
    seed_users
    
    users = @user_repo.where_not_in('id', [2])
    
    assert_equal 2, users.count
    refute users.any? { |u| u.id == 2 }
  end

  def test_first_returns_first_model
    seed_users
    
    user = @user_repo.first
    
    assert_instance_of RepoTestUser, user
    assert_equal 1, user.id
  end

  def test_count_returns_integer
    seed_users
    
    count = @user_repo.count
    
    assert_equal 3, count
  end

  def test_exists_with_id
    seed_users
    
    assert @user_repo.exists?(1)
    refute @user_repo.exists?(999)
  end

  def test_exists_without_id_checks_table
    seed_users
    
    assert @user_repo.exists?
    
    @db.execute_delete(@db.delete('users'))
    refute @user_repo.exists?
  end

  def test_update_returns_affected_count
    seed_users
    
    affected = @user_repo.update(1, name: 'Updated Alice', age: 29)
    
    assert_equal 1, affected
    
    user = @user_repo.find(1)
    assert_equal 'Updated Alice', user.name
    assert_equal 29, user.age
  end

  def test_delete_returns_affected_count
    seed_users
    
    affected = @user_repo.delete(1)
    
    assert_equal 1, affected
    assert_equal 2, @user_repo.count
  end

  def test_destroy_is_alias_for_delete
    seed_users
    
    affected = @user_repo.destroy(2)
    
    assert_equal 1, affected
  end

  def test_delete_where_with_conditions
    seed_users
    
    affected = @user_repo.delete_where(country: 'USA')
    
    assert_equal 2, affected
    assert_equal 1, @user_repo.count
  end

  def test_transaction
    result = @user_repo.transaction do
      @user_repo.insert(name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA')
    end
    
    assert_equal 1, @user_repo.count
  end

  def test_transaction_rolls_back_on_error
    begin
      @user_repo.transaction do
        @user_repo.insert(name: 'Alice', email: 'alice@example.com', age: 28, country: 'USA')
        raise 'Test error'
      end
    rescue => e
      # Expected
    end
    
    assert_equal 0, @user_repo.count
  end

  def test_execute_with_custom_query
    seed_users
    
    custom_query = @db.query('users').where('age', '>', 30).order_by('age', 'DESC')
    users = @user_repo.execute(custom_query)
    
    assert_equal 2, users.count
    assert users.all? { |u| u.is_a?(RepoTestUser) }
    assert_equal 'Charlie', users.first.name
  end

  def test_execute_first_with_custom_query
    seed_users
    
    custom_query = @db.query('users').where('country', 'UK')
    user = @user_repo.execute_first(custom_query)
    
    assert_instance_of RepoTestUser, user
    assert_equal 'Bob', user.name
  end

  def test_custom_repository_methods
    seed_users
    
    adults = @user_repo.adults
    
    assert_equal 3, adults.count
    assert adults.all? { |u| u.age >= 18 }
  end

  def test_multiple_repositories
    seed_users
    seed_posts
    
    users = @user_repo.all
    posts = @post_repo.all
    
    assert_equal 3, users.count
    assert_equal 3, posts.count
    assert users.all? { |u| u.is_a?(RepoTestUser) }
    assert posts.all? { |p| p.is_a?(RepoTestPost) }
  end

  def test_repository_without_table_raises_error
    repo_class = Class.new(QueryKit::Repository) do
      model RepoTestUser
    end
    
    repo = repo_class.new(@db)
    error = assert_raises(RuntimeError) { repo.all }
    assert_match(/Table name not configured/, error.message)
  end

  def test_repository_without_model_raises_error
    repo_class = Class.new(QueryKit::Repository) do
      table 'users'
    end
    
    repo = repo_class.new(@db)
    error = assert_raises(RuntimeError) { repo.all }
    assert_match(/Model class not configured/, error.message)
  end
end
