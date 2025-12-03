# frozen_string_literal: true

require_relative 'adapter'

module QueryKit
  module Adapters
    class PostgreSQLAdapter < Adapter
      def initialize(config)
        require 'pg'
        @conn = PG.connect(config)
      end

      def execute(sql, bindings = [])
        # Convert ? placeholders to $1, $2, etc.
        placeholder_count = 0
        sql = sql.gsub('?') { |_| "$#{placeholder_count += 1}" }
        
        @last_result = @conn.exec_params(sql, bindings)
        @last_result.map { |row| row }
      end

      def last_insert_id
        result = @conn.exec("SELECT lastval()")
        result[0]['lastval'].to_i
      rescue PG::Error
        nil
      end

      def affected_rows
        @last_result ? @last_result.cmd_tuples : 0
      end

      def begin_transaction
        @conn.exec("BEGIN")
      end

      def commit
        @conn.exec("COMMIT")
      end

      def rollback
        @conn.exec("ROLLBACK")
      end

      def close
        @conn.close
      end
    end
  end
end
