# frozen_string_literal: true

require 'mutex_m'

module QueryKit
  # Configuration class for global QueryKit settings
  #
  # @note This class is used internally by the global configuration methods.
  #   Most users should use {QueryKit.setup} or {QueryKit.configure} instead.
  class Configuration
    attr_accessor :adapter, :connection_options

    def initialize
      @adapter = nil
      @connection_options = {}
    end

    # Configure with adapter and options
    #
    # @param adapter [Symbol] the database adapter type
    # @param options [Hash] connection options
    # @return [void]
    def setup(adapter, options = {})
      @adapter = adapter
      @connection_options = options
    end

    # Check if configuration is set
    #
    # @return [Boolean] true if adapter is configured
    def configured?
      !@adapter.nil?
    end

    # Validate configuration
    #
    # @raise [ConfigurationError] if not configured
    # @return [void]
    def validate!
      raise ConfigurationError, "QueryKit not configured. Call QueryKit.configure first." unless configured?
    end
  end

  # Error raised when attempting to use QueryKit without configuration
  class ConfigurationError < StandardError; end

  class << self
    # Get the global configuration instance
    #
    # @return [Configuration] the global configuration object
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure QueryKit globally
    #
    # @yield [Configuration] the configuration object
    # @return [void]
    #
    # @example
    #   QueryKit.configure do |config|
    #     config.adapter = :sqlite
    #     config.connection_options = { database: 'db/app.db' }
    #   end
    def configure
      yield(configuration) if block_given?
    end

    # Setup with parameters (alternative to configure block)
    #
    # @param adapter [Symbol] the database adapter type (:sqlite, :postgresql, :mysql)
    # @param options [Hash] connection options specific to the adapter
    # @return [void]
    #
    # @example
    #   QueryKit.setup(:sqlite, database: 'db/app.db')
    # Setup with parameters (alternative to configure block)
    #
    # @param adapter [Symbol] the database adapter type (:sqlite, :postgresql, :mysql)
    # @param options [Hash] connection options specific to the adapter
    # @return [void]
    #
    # @example
    #   QueryKit.setup(:sqlite, database: 'db/app.db')
    def setup(adapter, options = {})
      configuration.setup(adapter, options)
    end

    # Get a connection using global configuration
    #
    # Creates a singleton connection that is reused across calls.
    # The connection is lazily initialized on first access.
    #
    # @return [QueryKit::Connection] the global connection instance
    # @raise [ConfigurationError] if QueryKit has not been configured
    #
    # @note Thread-safety: The connection singleton creation is thread-safe,
    #   but individual database operations depend on the underlying adapter's
    #   thread-safety. SQLite connections should not be shared across threads.
    #   For multi-threaded applications, create separate connections per thread
    #   using {QueryKit.connect} instead of using the global connection.
    #
    # @example Single-threaded usage (safe)
    #   QueryKit.setup(:sqlite, database: 'app.db')
    #   db = QueryKit.connection
    #   users = db.get(db.query('users'))
    #
    # @example Multi-threaded usage (use separate connections)
    #   threads = 10.times.map do
    #     Thread.new do
    #       # Create a new connection per thread
    #       db = QueryKit.connect(:sqlite, database: 'app.db')
    #       users = db.get(db.query('users'))
    #     end
    #   end
    #   threads.each(&:join)
    #
    # @see QueryKit.connect for creating separate connection instances
    def connection
      configuration.validate!
      
      # Thread-safe singleton initialization
      @connection_mutex ||= Mutex.new
      @connection_mutex.synchronize do
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
    end

    # Reset configuration (useful for testing)
    #
    # Clears the global configuration and connection singleton.
    #
    # @return [void]
    #
    # @note This method is primarily intended for testing. In production,
    #   you typically configure once at application startup.
    #
    # @example
    #   QueryKit.setup(:sqlite, database: 'test.db')
    #   # ... tests ...
    #   QueryKit.reset!
    #   QueryKit.setup(:sqlite, database: 'other.db')
    def reset!
      @connection_mutex&.synchronize do
        @connection = nil
      end
      @configuration = nil
      @connection_mutex = nil
    end
  end
end
