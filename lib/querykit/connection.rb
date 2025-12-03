# frozen_string_literal: true

module QueryKit
  # Connection class to manage database interactions.
  #
  # Provides methods for executing queries, managing transactions,
  # and optionally mapping results to model objects.
  #
  # @example Basic usage
  #   db = Quby.connect(:sqlite, database: 'app.db')
  #   query = db.query('users').where('age', '>', 18)
  #   users = db.get(query)
  #
  # @example With model mapping
  #   users = db.get(query, User)  # Returns array of User objects
  #
  # @example Transaction
  #   db.transaction do
  #     db.execute_insert(db.insert('users').values(name: 'John'))
  #     db.execute_update(db.update('posts').set(status: 'published'))
  #   end
  class Connection
    # @return [Adapter] the database adapter instance
    attr_reader :adapter

    # Initialize a new Connection with the given adapter.
    #
    # @param adapter [Adapter] a database adapter instance (SQLite, PostgreSQL, or MySQL)
    #
    # @example
    #   adapter = Quby::Adapters::SQLiteAdapter.new(database: 'app.db')
    #   connection = Quby::Connection.new(adapter)
    def initialize(adapter)
      @adapter = adapter
    end

    # Create a new query builder for the specified table.
    #
    # @param table [String, nil] the table name (can be set later with from())
    # @return [Query] a new query builder instance
    #
    # @example
    #   query = db.query('users').where('age', '>', 18)
    def query(table = nil)
      Query.new(table)
    end

    # Create a new query builder for the specified table (alias for query).
    #
    # @param table [String] the table name
    # @return [Query] a new query builder instance
    #
    # @example
    #   query = db.from('users').where('status', 'active')
    def from(table)
      Query.new(table)
    end

    # Create a new query builder for the specified table (alias for query).
    #
    # @param table [String] the table name
    # @return [Query] a new query builder instance
    #
    # @example
    #   query = db.table('users').select('*')
    def table(table)
      Query.new(table)
    end

    # Create a new INSERT query builder.
    #
    # @param table [String, nil] the table name
    # @return [InsertQuery] a new insert query builder instance
    #
    # @example
    #   insert = db.insert('users').values(name: 'John', email: 'john@example.com')
    def insert(table = nil)
      InsertQuery.new(table)
    end

    # Create a new UPDATE query builder.
    #
    # @param table [String, nil] the table name
    # @return [UpdateQuery] a new update query builder instance
    #
    # @example
    #   update = db.update('users').set(status: 'inactive').where('last_login', '<', '2020-01-01')
    def update(table = nil)
      UpdateQuery.new(table)
    end

    # Create a new DELETE query builder.
    #
    # @param table [String, nil] the table name
    # @return [DeleteQuery] a new delete query builder instance
    #
    # @example
    #   delete = db.delete('users').where('status', 'deleted')
    def delete(table = nil)
      DeleteQuery.new(table)
    end

    # Execute a SELECT query and return all results.
    #
    # @param query [Query] the query to execute
    # @param model_class [Class, nil] optional model class to map results to
    #
    # @return [Array<Hash>, Array<Object>] array of result hashes or model instances
    #
    # @example Get raw hashes
    #   users = db.get(db.query('users').where('age', '>', 18))
    #
    # @example Map to model objects
    #   users = db.get(db.query('users').where('age', '>', 18), User)
    def get(query, model_class = nil)
      sql = query.to_sql
      results = @adapter.execute(sql, query.bindings)
      return results unless model_class
      
      results.map { |row| map_to_model(row, model_class) }
    end

    # Execute a SELECT query and return the first result.
    #
    # @param query [Query] the query to execute
    # @param model_class [Class, nil] optional model class to map result to
    #
    # @return [Hash, Object, nil] result hash, model instance, or nil if no results
    #
    # @example
    #   user = db.first(db.query('users').where('email', 'john@example.com'))
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
