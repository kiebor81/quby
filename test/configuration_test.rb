# frozen_string_literal: true

require_relative 'test_helper'

# Test models for configuration tests
class ConfigTestUser
  attr_accessor :id, :name
  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
  end
end

class ConfigTestUserRepository < QueryKit::Repository
  table 'users'
  model ConfigTestUser
end

class ConfigTestRepo < QueryKit::Repository
  table 'test'
  model Object
end

class ConfigurationTest < Minitest::Test
  def setup
    # Ensure clean state
    QueryKit.reset!
  end

  def teardown
    # Reset after each test
    QueryKit.reset!
  end

  def test_configuration_instance
    config = QueryKit.configuration
    assert_instance_of QueryKit::Configuration, config
  end

  def test_configure_block
    QueryKit.configure do |config|
      config.adapter = :sqlite
      config.connection_options = { database: ':memory:' }
    end

    config = QueryKit.configuration
    assert_equal :sqlite, config.adapter
    assert_equal({ database: ':memory:' }, config.connection_options)
  end

  def test_setup_method
    QueryKit.setup(:sqlite, database: 'test.db')

    config = QueryKit.configuration
    assert_equal :sqlite, config.adapter
    assert_equal({ database: 'test.db' }, config.connection_options)
  end

  def test_configured_check
    config = QueryKit.configuration
    refute config.configured?

    QueryKit.setup(:sqlite, database: ':memory:')
    assert config.configured?
  end

  def test_connection_without_configuration
    error = assert_raises(QueryKit::ConfigurationError) do
      QueryKit.connection
    end
    assert_match(/not configured/, error.message)
  end

  def test_global_connection
    QueryKit.setup(:sqlite, database: ':memory:')
    
    connection = QueryKit.connection
    assert_instance_of QueryKit::Connection, connection
    
    # Should return same instance (memoized)
    connection2 = QueryKit.connection
    assert_same connection, connection2
  end

  def test_reset_clears_configuration
    QueryKit.setup(:sqlite, database: ':memory:')
    assert QueryKit.configuration.configured?

    QueryKit.reset!
    refute QueryKit.configuration.configured?
  end

  def test_reset_clears_connection
    QueryKit.setup(:sqlite, database: ':memory:')
    conn1 = QueryKit.connection

    QueryKit.reset!
    QueryKit.setup(:sqlite, database: ':memory:')
    conn2 = QueryKit.connection

    refute_same conn1, conn2
  end

  def test_repository_uses_global_connection
    QueryKit.setup(:sqlite, database: ':memory:')
    
    # Setup schema
    db = QueryKit.connection
    db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')

    # Create without passing connection
    repo = ConfigTestUserRepository.new
    assert_instance_of QueryKit::Connection, repo.db

    # Should work
    id = repo.create(name: 'Test User')
    assert_kind_of Integer, id
    assert id > 0
  end

  def test_repository_can_override_global_connection
    QueryKit.setup(:sqlite, database: ':memory:')
    
    custom_db = QueryKit.connect(:sqlite, ':memory:')
    
    repo_global = ConfigTestRepo.new
    repo_custom = ConfigTestRepo.new(custom_db)

    refute_same repo_global.db, repo_custom.db
  end

  def test_query_builder_with_global_connection
    QueryKit.setup(:sqlite, database: ':memory:')
    
    connection = QueryKit.connection
    query = connection.query('users')
    
    assert_instance_of QueryKit::Query, query
    assert_equal 'SELECT * FROM users', query.to_sql
  end

  private

  def setup_test_db
    db = QueryKit.connect(:sqlite, 'test_config.db')
    db.raw('DROP TABLE IF EXISTS users')
    db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')
  end
end
