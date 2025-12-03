# frozen_string_literal: true

module QueryKit
  # DeleteQuery class for building SQL DELETE statements.
  class DeleteQuery
    attr_reader :table, :wheres, :bindings

    # Initialize a new DeleteQuery instance.
    def initialize(table = nil)
      @table = table
      @wheres = []
      @bindings = []
    end

    # Set the table to delete from.
    def from(table)
      @table = table
      self
    end

    # Add a WHERE condition to the delete query.
    def where(column, operator = nil, value = nil)
      if value.nil? && !operator.nil?
        value = operator
        operator = '='
      end

      @wheres << { type: 'basic', column: column, operator: operator, value: value, boolean: 'AND' }
      @bindings << value
      self
    end

    # Generate the SQL DELETE statement.
    def to_sql
      raise "No table specified" unless @table

      sql = []
      sql << "DELETE FROM #{@table}"

      unless @wheres.empty?
        sql << "WHERE"
        where_clauses = @wheres.map { |w| "#{w[:column]} #{w[:operator]} ?" }
        sql << where_clauses.join(' AND ')
      end

      sql.join(' ')
    end

    # Return the SQL DELETE statement as a string.
    def to_s
      to_sql
    end
  end
end
