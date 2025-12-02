# frozen_string_literal: true

module Quby
  # Connection class to manage database interactions
  class Connection
    attr_reader :adapter

    # Initialize a new Connection with the given adapter.
    def initialize(adapter)
      @adapter = adapter
    end

    # Query builder factory methods
    def query(table = nil)
      Query.new(table)
    end

    # Set the table
    def from(table)
      Query.new(table)
    end

    # Set the table
    def table(table)
      Query.new(table)
    end

    # Build an InsertQuery
    def insert(table = nil)
      InsertQuery.new(table)
    end

    # Build an UpdateQuery
    def update(table = nil)
      UpdateQuery.new(table)
    end

    # Build a DeleteQuery
    def delete(table = nil)
      DeleteQuery.new(table)
    end

    # Execute queries and optionally map to model objects
    def get(query, model_class = nil)
      sql = query.to_sql
      results = @adapter.execute(sql, query.bindings)
      return results unless model_class
      
      results.map { |row| map_to_model(row, model_class) }
    end

    # Get the first result of a query and optionally map to model object
    def first(query, model_class = nil)
      query.limit(1)
      results = @adapter.execute(query.to_sql, query.bindings)
      return nil if results.empty?
      
      row = results.first
      model_class ? map_to_model(row, model_class) : row
    end

    # Execute an insert query and return the last insert ID
    def execute_insert(query)
      sql = query.to_sql
      @adapter.execute(sql, query.bindings)
      @adapter.last_insert_id
    end

    # Execute an update query and return the number of affected rows
    def execute_update(query)
      sql = query.to_sql
      @adapter.execute(sql, query.bindings)
      @adapter.affected_rows
    end

    # Execute a delete query and return the number of affected rows
    def execute_delete(query)
      sql = query.to_sql
      @adapter.execute(sql, query.bindings)
      @adapter.affected_rows
    end

    # Execute a query and return a scalar value (first column of first row)
    # Useful for aggregate queries like COUNT, SUM, AVG, etc.
    def execute_scalar(query)
      result = first(query)
      return nil if result.nil?
      result.is_a?(Hash) ? result.values.first : result
    end

    # Raw SQL with optional model mapping
    def raw(sql, *bindings, model_class: nil)
      results = @adapter.execute(sql, bindings.flatten)
      return results unless model_class
      
      results.map { |row| map_to_model(row, model_class) }
    end

    # Transaction support
    def transaction
      @adapter.begin_transaction
      result = yield
      @adapter.commit
      result
    rescue => e
      @adapter.rollback
      raise e
    end

    private

    # Map a hash to a model instance
    def map_to_model(hash, model_class)
      # Convert string keys to symbols for better Ruby convention
      symbolized = hash.transform_keys(&:to_sym)
      
      # Try different initialization strategies
      if model_class.instance_method(:initialize).arity == 0
        # No-arg constructor - set attributes after creation
        instance = model_class.new
        symbolized.each do |key, value|
          setter = "#{key}="
          instance.send(setter, value) if instance.respond_to?(setter)
        end
        instance
      else
        # Constructor accepts hash
        model_class.new(symbolized)
      end
    end
  end
end
