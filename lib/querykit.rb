# frozen_string_literal: true

# QueryKit - A lightweight query builder for Ruby
# Inspired by SqlKata, built for simplicity
#
# @author kiebor81
# @since 0.1.0

require 'date'
require 'time'

require_relative 'querykit/version'
require_relative 'querykit/configuration'
require_relative 'querykit/query'
require_relative 'querykit/insert_query'
require_relative 'querykit/update_query'
require_relative 'querykit/delete_query'
require_relative 'querykit/connection'
require_relative 'querykit/repository'
require_relative 'querykit/adapters/adapter'
require_relative 'querykit/adapters/sqlite_adapter'
require_relative 'querykit/adapters/postgresql_adapter'
require_relative 'querykit/adapters/mysql_adapter'

# QueryKit is a lightweight, fluent query builder and micro-ORM for Ruby.
# It provides a clean, chainable API for building SQL queries without the
# overhead of Active Record.
#
# @example Basic usage
#   db = QueryKit.connect(:sqlite, database: 'app.db')
#   users = db.get(db.query('users').where('age', '>', 18))
#
# @example Using repository pattern
#   class UserRepository < QueryKit::Repository
#     table 'users'
#     model User
#   end
#   repo = UserRepository.new(db)
#   user = repo.find(1)
module QueryKit
  # Factory method for creating database connections
  #
  # @param adapter_type [Symbol] The type of database adapter to use
  #   (:sqlite, :postgresql, :postgres, or :mysql)
  # @param config [Hash, String] Configuration for the adapter. For SQLite,
  #   can be a string path to the database file or a hash with :database key.
  #   For PostgreSQL/MySQL, should be a hash with connection parameters.
  #
  # @return [Connection] A new database connection instance
  #
  # @raise [ArgumentError] if adapter_type is not supported
  #
  # @example SQLite connection
  #   db = QueryKit.connect(:sqlite, database: 'app.db')
  #   # or
  #   db = QueryKit.connect(:sqlite, 'app.db')
  #
  # @example PostgreSQL connection
  #   db = QueryKit.connect(:postgresql, 
  #     host: 'localhost',
  #     database: 'myapp',
  #     user: 'postgres',
  #     password: 'secret'
  #   )
  #
  # @example MySQL connection
  #   db = QueryKit.connect(:mysql,
  #     host: 'localhost',
  #     database: 'myapp',
  #     username: 'root',
  #     password: 'secret'
  #   )
  def self.connect(adapter_type, config)
    adapter = case adapter_type
    when :sqlite
      Adapters::SQLiteAdapter.new(config)
    when :postgresql, :postgres
      Adapters::PostgreSQLAdapter.new(config)
    when :mysql
      Adapters::MySQLAdapter.new(config)
    else
      raise ArgumentError, "Unknown adapter type: #{adapter_type}. " \
                           "Supported types: :sqlite, :postgresql, :mysql"
    end

    Connection.new(adapter)
  end

  # Load extensions into QueryKit
  #
  # Extensions are prepended to the Query class to allow method overrides
  # and additional functionality. This enables opt-in features while keeping
  # the core library minimal.
  #
  # @param extensions [Module, Array<Module>] One or more extension modules to load
  #
  # @return [void]
  #
  # @example Load single extension
  #   require 'querykit/extensions/case_when'
  #   QueryKit.use_extensions(QueryKit::CaseWhenExtension)
  #
  # @example Load multiple extensions
  #   QueryKit.use_extensions([QueryKit::CaseWhenExtension, MyCustomExtension])
  def self.use_extensions(*extensions)
    extensions.flatten.each do |extension|
      Query.prepend(extension)
    end
  end
end
