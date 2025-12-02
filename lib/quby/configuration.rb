# frozen_string_literal: true

module Quby
  class Configuration
    attr_accessor :adapter, :connection_options

    def initialize
      @adapter = nil
      @connection_options = {}
    end

    # Configure with adapter and options
    def setup(adapter, options = {})
      @adapter = adapter
      @connection_options = options
    end

    # Check if configuration is set
    def configured?
      !@adapter.nil?
    end

    # Validate configuration
    def validate!
      raise ConfigurationError, "Quby not configured. Call Quby.configure first." unless configured?
    end
  end

  class ConfigurationError < StandardError; end

  class << self
    # Get the global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure Quby globally
    # @example
    #   Quby.configure do |config|
    #     config.adapter = :sqlite
    #     config.connection_options = { database: 'db/app.db' }
    #   end
    def configure
      yield(configuration) if block_given?
    end

    # Setup with parameters (alternative to configure block)
    # @example
    #   Quby.setup(:sqlite, database: 'db/app.db')
    def setup(adapter, options = {})
      configuration.setup(adapter, options)
    end

    # Get a connection using global configuration
    # @return [Quby::Connection]
    def connection
      configuration.validate!
      
      @connection ||= begin
        # Normalize connection options for SQLite (expects string path)
        config = if configuration.adapter == :sqlite
          configuration.connection_options[:database] || configuration.connection_options
        else
          configuration.connection_options
        end
        
        connect(configuration.adapter, config)
      end
    end

    # Reset configuration (useful for testing)
    def reset!
      @configuration = nil
      @connection = nil
    end
  end
end
