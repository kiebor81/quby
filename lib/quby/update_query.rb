# frozen_string_literal: true

module Quby
  # UpdateQuery class for building SQL UPDATE statements.
  class UpdateQuery
    attr_reader :table, :values, :wheres, :bindings

    # Initialize a new UpdateQuery instance.
    def initialize(table = nil)
      @table = table
      @values = {}
      @wheres = []
      @bindings = []
    end

    # Set the values to update.
    def set(data)
      @values.merge!(data)
      self
    end

    # Add a WHERE condition to the update query.
    def where(column, operator = nil, value = nil)
      if value.nil? && !operator.nil?
        value = operator
        operator = '='
      end

      @wheres << { type: 'basic', column: column, operator: operator, value: value, boolean: 'AND' }
      self
    end

    # Generate the SQL UPDATE statement.
    def to_sql
      raise "No table specified" unless @table
      raise "No values to update" if @values.empty?

      @bindings = @values.values + @wheres.map { |w| w[:value] }

      sql = []
      sql << "UPDATE #{@table}"
      sql << "SET"
      sql << @values.keys.map { |k| "#{k} = ?" }.join(', ')

      unless @wheres.empty?
        sql << "WHERE"
        where_clauses = @wheres.map { |w| "#{w[:column]} #{w[:operator]} ?" }
        sql << where_clauses.join(' AND ')
      end

      sql.join(' ')
    end

    # Return the SQL UPDATE statement as a string.
    def to_s
      to_sql
    end
  end
end
