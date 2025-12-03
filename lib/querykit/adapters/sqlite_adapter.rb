# frozen_string_literal: true

require_relative 'adapter'

module QueryKit
  module Adapters
    class SQLiteAdapter < Adapter
      def initialize(database_path)
        require 'sqlite3'
        @db = SQLite3::Database.new(database_path)
        @db.results_as_hash = true
      end

      def execute(sql, bindings = [])
        @db.execute(sql, bindings)
      end

      def last_insert_id
        @db.last_insert_row_id
      end

      def affected_rows
        @db.changes
      end

      def begin_transaction
        @db.execute("BEGIN TRANSACTION")
      end

      def commit
        @db.execute("COMMIT")
      end

      def rollback
        @db.execute("ROLLBACK")
      end

      def close
        @db.close
      end
    end
  end
end
