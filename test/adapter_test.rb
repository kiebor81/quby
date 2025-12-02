# frozen_string_literal: true

require_relative 'test_helper'

class AdapterTest < Minitest::Test
  def test_sqlite_adapter_initialization
    adapter = Quby::Adapters::SQLiteAdapter.new(':memory:')
    assert_instance_of Quby::Adapters::SQLiteAdapter, adapter
    adapter.close
  end

  def test_adapter_base_class_not_implemented
    adapter = Quby::Adapters::Adapter.new
    
    assert_raises(NotImplementedError) { adapter.execute('SELECT 1') }
    assert_raises(NotImplementedError) { adapter.begin_transaction }
    assert_raises(NotImplementedError) { adapter.commit }
    assert_raises(NotImplementedError) { adapter.rollback }
  end

  def test_connect_factory_method_sqlite
    db = Quby.connect(:sqlite, ':memory:')
    assert_instance_of Quby::Connection, db
    assert_instance_of Quby::Adapters::SQLiteAdapter, db.adapter
  end

  def test_connect_factory_method_invalid_adapter
    error = assert_raises(ArgumentError) do
      Quby.connect(:invalid_db, {})
    end
    
    assert_match(/Unknown adapter type/, error.message)
    assert_match(/invalid_db/, error.message)
  end

  def test_sqlite_adapter_execute
    adapter = Quby::Adapters::SQLiteAdapter.new(':memory:')
    adapter.execute('CREATE TABLE test (id INTEGER, name TEXT)')
    adapter.execute('INSERT INTO test VALUES (?, ?)', [1, 'Alice'])
    
    results = adapter.execute('SELECT * FROM test WHERE id = ?', [1])
    
    assert_equal 1, results.length
    assert_equal 1, results[0]['id']
    assert_equal 'Alice', results[0]['name']
    
    adapter.close
  end

  def test_sqlite_adapter_transactions
    adapter = Quby::Adapters::SQLiteAdapter.new(':memory:')
    adapter.execute('CREATE TABLE test (id INTEGER, name TEXT)')
    
    adapter.begin_transaction
    adapter.execute('INSERT INTO test VALUES (?, ?)', [1, 'Alice'])
    adapter.commit
    
    results = adapter.execute('SELECT * FROM test')
    assert_equal 1, results.length
    
    adapter.close
  end

  def test_sqlite_adapter_rollback
    adapter = Quby::Adapters::SQLiteAdapter.new(':memory:')
    adapter.execute('CREATE TABLE test (id INTEGER, name TEXT)')
    
    adapter.begin_transaction
    adapter.execute('INSERT INTO test VALUES (?, ?)', [1, 'Alice'])
    adapter.rollback
    
    results = adapter.execute('SELECT * FROM test')
    assert_equal 0, results.length
    
    adapter.close
  end
end
