# frozen_string_literal: true

require_relative 'test_helper'

class UpdateQueryTest < Minitest::Test
  def test_basic_update
    query = QueryKit::UpdateQuery.new('users')
      .set(name: 'Jane', age: 30)
      .where('id', 1)

    assert_equal 'UPDATE users SET name = ?, age = ? WHERE id = ?', query.to_sql
    assert_equal ['Jane', 30, 1], query.bindings
  end

  def test_update_with_multiple_conditions
    query = QueryKit::UpdateQuery.new('users')
      .set(status: 'inactive')
      .where('age', '<', 18)
      .where('country', 'USA')

    assert_equal 'UPDATE users SET status = ? WHERE age < ? AND country = ?', query.to_sql
    assert_equal ['inactive', 18, 'USA'], query.bindings
  end

  def test_no_table_raises_error
    query = QueryKit::UpdateQuery.new.set(name: 'Alice')
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No table specified', error.message
  end

  def test_no_values_raises_error
    query = QueryKit::UpdateQuery.new('users').where('id', 1)
    error = assert_raises(RuntimeError) { query.to_sql }
    assert_equal 'No values to update', error.message
  end
end
