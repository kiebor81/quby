# frozen_string_literal: true

require_relative 'adapter'

module Quby
  module Adapters
    class MySQLAdapter < Adapter
      def initialize(config)
        require 'mysql2'
        @client = Mysql2::Client.new(config)
      end

      def execute(sql, bindings = [])
        stmt = @client.prepare(sql)
        @last_result = stmt.execute(*bindings)
        @last_result.map { |row| row }
      end

      def last_insert_id
        @client.last_id
      end

      def affected_rows
        @last_result ? @last_result.count : 0
      end

      def begin_transaction
        @client.query("START TRANSACTION")
      end

      def commit
        @client.query("COMMIT")
      end

      def rollback
        @client.query("ROLLBACK")
      end

      def close
        @client.close
      end
    end
  end
end
