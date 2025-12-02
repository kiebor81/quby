# frozen_string_literal: true

module Quby
  # Builder for CASE WHEN expressions
  # Used internally by Query when select_case is called
  class CaseBuilder
    attr_reader :column, :whens, :else_value, :alias_name

    def initialize(column = nil)
      @column = column
      @whens = []
      @else_value = nil
      @alias_name = nil
    end

    # Add a WHEN condition
    # @param condition [String, Array] Column name or [column, operator, value]
    # @param operator [String, Object] Operator or value if condition is column name
    # @param value [Object] Value to compare (only if operator provided)
    def when(condition, operator = nil, value = nil)
      if @column && operator.nil?
        # Simple CASE with column: when('value') -> WHEN ? (comparing against @column)
        @whens << { value: condition, then: nil }
      elsif value.nil? && !operator.nil?
        # when('age', 18) -> WHEN age = 18
        @whens << { column: condition, operator: '=', value: operator, then: nil }
      elsif !value.nil?
        # when('age', '>', 18) -> WHEN age > 18
        @whens << { column: condition, operator: operator, value: value, then: nil }
      else
        # when('age > 18') -> WHEN age > 18 (raw condition)
        @whens << { raw: condition, then: nil }
      end
      self
    end

    # Set the THEN value for the last WHEN
    def then(value)
      raise 'No WHEN clause to add THEN to' if @whens.empty?
      @whens.last[:then] = value
      self
    end

    # Set the ELSE value
    def else(value)
      @else_value = value
      self
    end

    # Set the alias for the CASE expression
    def as(alias_name)
      @alias_name = alias_name
      self
    end

    # Build the CASE expression
    def to_sql
      raise 'CASE expression must have at least one WHEN clause' if @whens.empty?
      
      sql = 'CASE'
      sql += " #{@column}" if @column
      
      @whens.each do |w|
        if w[:raw]
          sql += " WHEN #{w[:raw]} THEN ?"
        elsif @column
          # Simple CASE: CASE column WHEN value THEN result
          sql += " WHEN ? THEN ?"
        else
          # Searched CASE: CASE WHEN column op value THEN result
          sql += " WHEN #{w[:column]} #{w[:operator]} ? THEN ?"
        end
      end
      
      sql += ' ELSE ?' if @else_value
      sql += ' END'
      sql += " AS #{@alias_name}" if @alias_name
      
      sql
    end

    # Get bindings for the CASE expression
    def bindings
      bindings = []
      
      @whens.each do |w|
        if @column && !w[:raw]
          # Simple CASE: need value in WHEN clause
          bindings << w[:value]
        elsif !w[:raw]
          # Searched CASE: value goes in condition
          bindings << w[:value]
        end
        bindings << w[:then]
      end
      
      bindings << @else_value if @else_value
      
      bindings
    end
  end
end
