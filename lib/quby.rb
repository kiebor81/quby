# frozen_string_literal: true

# Quby - A lightweight query builder for Ruby
# Inspired by SqlKata, built for simplicity

require 'date'
require 'time'

require_relative 'quby/version'
require_relative 'quby/configuration'
require_relative 'quby/query'
require_relative 'quby/insert_query'
require_relative 'quby/update_query'
require_relative 'quby/delete_query'
require_relative 'quby/connection'
require_relative 'quby/repository'
require_relative 'quby/adapters/adapter'
require_relative 'quby/adapters/sqlite_adapter'
require_relative 'quby/adapters/postgresql_adapter'
require_relative 'quby/adapters/mysql_adapter'

module Quby
  # Factory method for creating database connections
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

  # Load extensions into Quby
  # Extensions are prepended to Query class to allow method overrides
  # @param extensions [Array<Module>] Array of extension modules to load
  # @example
  #   Quby.use_extensions(Quby::CaseWhenExtension)
  #   Quby.use_extensions([Quby::CaseWhenExtension, Quby::MyCustomExtension])
  def self.use_extensions(*extensions)
    extensions.flatten.each do |extension|
      Query.prepend(extension)
    end
  end
end
