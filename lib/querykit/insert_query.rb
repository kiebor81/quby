# frozen_string_literal: true

module QueryKit
  # InsertQuery class for building INSERT SQL queries
  class InsertQuery
    attr_reader :table, :values, :bindings

    # Initialize a new InsertQuery instance.
    def initialize(table = nil)
      @table = table
      @values = []
      @bindings = []
    end

    # Set the table to insert into.
    def into(table)
      @table = table
      self
    end

    # Set the table to insert into.
    def values(data)
      if data.is_a?(Hash)
        @values << data
      elsif data.is_a?(Array)
        @values.concat(data)
      end
      self
    end

    # Generate the SQL INSERT statement.
    def to_sql
      raise "No table specified" unless @table
      raise "No values specified" if @values.empty?

      first_row = @values.first
      columns = first_row.keys
      @bindings = @values.flat_map { |row| columns.map { |col| row[col] } }

      sql = []
      sql << "INSERT INTO #{@table}"
      sql << "(#{columns.join(', ')})"
      sql << "VALUES"

      value_sets = @values.map do |row|
        placeholders = (['?'] * columns.size).join(', ')
        "(#{placeholders})"
      end

      sql << value_sets.join(', ')
      sql.join(' ')
    end

    def to_s
      to_sql
    end
  end
end
