# frozen_string_literal: true

require_relative 'test_helper'

class DeleteQueryTest < Minitest::Test
  def test_basic_delete
    query = QueryKit::DeleteQuery.new('users').where('id', 1)
    assert_equal 'DELETE FROM users WHERE id = ?', query.to_sql
    assert_equal [1], query.bindings
  end

  def test_delete_with_multiple_conditions
    query = QueryKit::DeleteQuery.new('users')
      .where('status', 'banned')
      .where('age', '<', 18)

    assert_equal 'DELETE FROM users WHERE status = ? AND age < ?', query.to_sql
    assert_equal ['banned', 18], query.bindings
  end

  def test_from_method
    query = QueryKit::DeleteQuery.new.from('users').where('id', 1)
    assert_equal 'DELETE FROM users WHERE id = ?', query.to_sql
  end

  def test_delete_without_where
    query = QueryKit::DeleteQuery.new('users')
    assert_equal 'DELETE FROM users', query.to_sql
    assert_empty query.bindings
  end

  def test_no_table_raises_error
    query = QueryKit::DeleteQuery.new
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No table specified', error.message
  end
end
