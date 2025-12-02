# frozen_string_literal: true

module Quby
  # Base repository class for implementing the repository pattern
  # 
  # Usage:
  #   class UserRepository < Quby::Repository
  #     table 'users'
  #     model User
  #   end
  #
  #   repo = UserRepository.new(db)
  #   user = repo.find(1)
  #   users = repo.all
  #   users = repo.where('age', '>', 18)
  class Repository
    attr_reader :db

    class << self
      # Set the table name for this repository
      def table(name)
        @table_name = name
      end
      
      # Set the model class for this repository
      def model(klass)
        @model_class = klass
      end
      
      # Get the table name
      def table_name
        @table_name
      end
      
      # Get the model class
      def model_class
        @model_class
      end
    end
    
    attr_reader :db
    
    # Initialize repository with optional database connection
    # If no connection provided, uses global Quby.connection
    # @param db [Quby::Connection, nil] Database connection
    def initialize(db = nil)
      @db = db || Quby.connection
    end
    
    # Get all records
    def all
      @db.get(query, model_class)
    end
    
    # Find a record by ID
    def find(id)
      @db.first(query.where('id', id), model_class)
    end
    
    # Find a record by column value
    def find_by(column, value)
      @db.first(query.where(column, value), model_class)
    end
    
    # Find multiple records by column value
    def where(column, operator_or_value, value = nil)
      if value.nil?
        # Two arguments: column and value (assumes =)
        @db.get(query.where(column, operator_or_value), model_class)
      else
        # Three arguments: column, operator, value
        @db.get(query.where(column, operator_or_value, value), model_class)
      end
    end
    
    # Find records where column is IN array
    def where_in(column, values)
      @db.get(query.where_in(column, values), model_class)
    end
    
    # Find records where column is NOT IN array
    def where_not_in(column, values)
      @db.get(query.where_not_in(column, values), model_class)
    end
    
    # Get first record matching conditions
    def first
      @db.first(query, model_class)
    end
    
    # Count all records
    def count
      result = @db.first(query.select('COUNT(*) as count'))
      result ? result['count'] : 0
    end
    
    # Check if any records exist
    def exists?(id = nil)
      if id
        count_query = query.select('COUNT(*) as count').where('id', id)
      else
        count_query = query.select('COUNT(*) as count')
      end
      
      result = @db.first(count_query)
      result && result['count'] > 0
    end
    
    # Insert a new record
    # @param attributes [Hash] The attributes for the new record
    # @return [Integer] The ID of the inserted record
    def insert(attributes)
      @db.execute_insert(@db.insert(table_name).values(attributes))
    end
    alias_method :create, :insert
    
    # Update a record by ID
    # @param id [Integer] The record ID
    # @param attributes [Hash] The attributes to update
    # @return [Integer] Number of affected rows
    def update(id, attributes)
      @db.execute_update(@db.update(table_name).set(attributes).where('id', id))
    end
    
    # Delete a record by ID
    # @param id [Integer] The record ID
    # @return [Integer] Number of affected rows
    def delete(id)
      @db.execute_delete(@db.delete(table_name).where('id', id))
    end
    alias_method :destroy, :delete
    
    # Delete all records matching conditions
    # @param conditions [Hash] WHERE conditions
    # @return [Integer] Number of affected rows
    def delete_where(conditions)
      delete_query = @db.delete(table_name)
      conditions.each { |column, value| delete_query.where(column, value) }
      @db.execute_delete(delete_query)
    end
    
    # Execute a custom query with model mapping
    # @param custom_query [Quby::Query] A custom query object
    # @return [Array] Array of model instances
    def execute(custom_query)
      @db.get(custom_query, model_class)
    end
    
    # Execute a custom query and return first result
    # @param custom_query [Quby::Query] A custom query object
    # @return [Object, nil] Model instance or nil
    def execute_first(custom_query)
      @db.first(custom_query, model_class)
    end
    
    # Begin a transaction
    def transaction(&block)
      @db.transaction(&block)
    end
    
    protected
    
    # Get a new query object for this repository's table
    def query
      @db.query(table_name)
    end
    
    # Get the table name from class configuration
    def table_name
      name = self.class.table_name
      raise "Table name not configured for #{self.class.name}. Use: table 'table_name'" unless name
      name
    end
    
    # Get the model class from class configuration
    def model_class
      klass = self.class.model_class
      raise "Model class not configured for #{self.class.name}. Use: model ModelClass" unless klass
      klass
    end
  end
end
