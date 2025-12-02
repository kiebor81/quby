# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/quby'
require_relative '../lib/quby/extensions/case_when'

# Enable the extension for testing
Quby::Query.prepend(Quby::CaseWhenExtension)

class CaseWhenTest < Minitest::Test
  def setup
    @query = Quby::Query.new
    @query.from('users')
  end

  def test_simple_case_with_column
    case_expr = @query.select_case('status')
      .when('active').then('Active User')
      .when('inactive').then('Inactive User')
      .else('Unknown')
      .as('status_label')
    
    @query.select('name', case_expr.to_sql)
    
    sql = case_expr.to_sql
    assert_includes sql, 'CASE status'
    assert_includes sql, 'WHEN ?'  # Simple CASE syntax
    assert_includes sql, 'THEN ?'
    assert_includes sql, 'ELSE ?'
    assert_includes sql, 'END AS status_label'
    
    bindings = case_expr.bindings
    assert_equal ['active', 'Active User', 'inactive', 'Inactive User', 'Unknown'], bindings
  end

  def test_searched_case_without_column
    case_expr = @query.select_case
      .when('age', '<', 18).then('minor')
      .when('age', '<', 65).then('adult')
      .else('senior')
      .as('age_group')
    
    sql = case_expr.to_sql
    assert_includes sql, 'CASE WHEN age < ? THEN ?'
    assert_includes sql, 'WHEN age < ? THEN ?'
    assert_includes sql, 'ELSE ?'
    assert_includes sql, 'END AS age_group'
    
    bindings = case_expr.bindings
    assert_equal [18, 'minor', 65, 'adult', 'senior'], bindings
  end

  def test_case_with_equals_operator
    case_expr = @query.select_case
      .when('country', 'USA').then('United States')
      .when('country', 'UK').then('United Kingdom')
      .as('country_name')
    
    sql = case_expr.to_sql
    assert_includes sql, 'WHEN country = ? THEN ?'
    
    bindings = case_expr.bindings
    assert_equal ['USA', 'United States', 'UK', 'United Kingdom'], bindings
  end

  def test_case_without_else
    case_expr = @query.select_case('role')
      .when('admin').then('Administrator')
      .when('user').then('Regular User')
      .as('role_label')
    
    sql = case_expr.to_sql
    refute_includes sql, 'ELSE'
    assert_includes sql, 'END AS role_label'
  end

  def test_case_without_alias
    case_expr = @query.select_case('status')
      .when('active').then('Active')
      .else('Inactive')
    
    sql = case_expr.to_sql
    refute_includes sql, ' AS '
    assert_match /END$/, sql
  end

  def test_case_with_raw_conditions
    case_expr = @query.select_case
      .when('age > 18 AND country = "USA"').then('Adult American')
      .else('Other')
      .as('category')
    
    sql = case_expr.to_sql
    assert_includes sql, 'WHEN age > 18 AND country = "USA" THEN ?'
    
    bindings = case_expr.bindings
    assert_equal ['Adult American', 'Other'], bindings
  end

  def test_case_with_multiple_operators
    case_expr = @query.select_case
      .when('score', '>=', 90).then('A')
      .when('score', '>=', 80).then('B')
      .when('score', '>=', 70).then('C')
      .else('F')
      .as('grade')
    
    sql = case_expr.to_sql
    assert_includes sql, 'WHEN score >= ? THEN ?'
    
    bindings = case_expr.bindings
    assert_equal [90, 'A', 80, 'B', 70, 'C', 'F'], bindings
  end

  def test_case_requires_at_least_one_when
    case_expr = @query.select_case('status')
    
    error = assert_raises(RuntimeError) do
      case_expr.to_sql
    end
    
    assert_equal 'CASE expression must have at least one WHEN clause', error.message
  end

  def test_then_without_when_raises_error
    case_expr = @query.select_case('status')
    
    error = assert_raises(RuntimeError) do
      case_expr.then('value')
    end
    
    assert_equal 'No WHEN clause to add THEN to', error.message
  end

  def test_case_with_numeric_values
    case_expr = @query.select_case
      .when('priority', 1).then('High')
      .when('priority', 2).then('Medium')
      .when('priority', 3).then('Low')
      .as('priority_label')
    
    bindings = case_expr.bindings
    assert_equal [1, 'High', 2, 'Medium', 3, 'Low'], bindings
  end

  def test_case_builder_is_chainable
    case_expr = @query.select_case('status')
    
    result = case_expr.when('active').then('Active')
    assert_same case_expr, result
    
    result = case_expr.else('Inactive')
    assert_same case_expr, result
    
    result = case_expr.as('label')
    assert_same case_expr, result
  end

  def test_multiple_case_expressions_in_query
    @query.select('name')
    
    case1 = @query.select_case
      .when('age', '<', 18).then('minor')
      .else('adult')
      .as('age_group')
    
    case2 = @query.select_case('status')
      .when('active').then('Active')
      .else('Inactive')
      .as('status_label')
    
    # Both case expressions should be independent
    assert_equal 3, case1.bindings.length # age value + 2 then values (minor, adult)
    assert_equal 3, case2.bindings.length # 1 when value (active) + 1 then (Active) + 1 else (Inactive)
  end
end
