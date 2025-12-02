# frozen_string_literal: true

require_relative 'test_helper'

# Test models for configuration tests
class ConfigTestUser
  attr_accessor :id, :name
  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
  end
end

class ConfigTestUserRepository < Quby::Repository
  table 'users'
  model ConfigTestUser
end

class ConfigTestRepo < Quby::Repository
  table 'test'
  model Object
end

class ConfigurationTest < Minitest::Test
  def setup
    # Ensure clean state
    Quby.reset!
  end

  def teardown
    # Reset after each test
    Quby.reset!
  end

  def test_configuration_instance
    config = Quby.configuration
    assert_instance_of Quby::Configuration, config
  end

  def test_configure_block
    Quby.configure do |config|
      config.adapter = :sqlite
      config.connection_options = { database: ':memory:' }
    end

    config = Quby.configuration
    assert_equal :sqlite, config.adapter
    assert_equal({ database: ':memory:' }, config.connection_options)
  end

  def test_setup_method
    Quby.setup(:sqlite, database: 'test.db')

    config = Quby.configuration
    assert_equal :sqlite, config.adapter
    assert_equal({ database: 'test.db' }, config.connection_options)
  end

  def test_configured_check
    config = Quby.configuration
    refute config.configured?

    Quby.setup(:sqlite, database: ':memory:')
    assert config.configured?
  end

  def test_connection_without_configuration
    error = assert_raises(Quby::ConfigurationError) do
      Quby.connection
    end
    assert_match(/not configured/, error.message)
  end

  def test_global_connection
    Quby.setup(:sqlite, database: ':memory:')
    
    connection = Quby.connection
    assert_instance_of Quby::Connection, connection
    
    # Should return same instance (memoized)
    connection2 = Quby.connection
    assert_same connection, connection2
  end

  def test_reset_clears_configuration
    Quby.setup(:sqlite, database: ':memory:')
    assert Quby.configuration.configured?

    Quby.reset!
    refute Quby.configuration.configured?
  end

  def test_reset_clears_connection
    Quby.setup(:sqlite, database: ':memory:')
    conn1 = Quby.connection

    Quby.reset!
    Quby.setup(:sqlite, database: ':memory:')
    conn2 = Quby.connection

    refute_same conn1, conn2
  end

  def test_repository_uses_global_connection
    Quby.setup(:sqlite, database: ':memory:')
    
    # Setup schema
    db = Quby.connection
    db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')

    # Create without passing connection
    repo = ConfigTestUserRepository.new
    assert_instance_of Quby::Connection, repo.db

    # Should work
    id = repo.create(name: 'Test User')
    assert_kind_of Integer, id
    assert id > 0
  end

  def test_repository_can_override_global_connection
    Quby.setup(:sqlite, database: ':memory:')
    
    custom_db = Quby.connect(:sqlite, ':memory:')
    
    repo_global = ConfigTestRepo.new
    repo_custom = ConfigTestRepo.new(custom_db)

    refute_same repo_global.db, repo_custom.db
  end

  def test_query_builder_with_global_connection
    Quby.setup(:sqlite, database: ':memory:')
    
    connection = Quby.connection
    query = connection.query('users')
    
    assert_instance_of Quby::Query, query
    assert_equal 'SELECT * FROM users', query.to_sql
  end

  private

  def setup_test_db
    db = Quby.connect(:sqlite, 'test_config.db')
    db.raw('DROP TABLE IF EXISTS users')
    db.raw('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)')
  end
end
