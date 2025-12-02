# frozen_string_literal: true

module Quby
  module Adapters
    # Abstract adapter base class
    class Adapter
      def execute(sql, bindings = [])
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      def begin_transaction
        raise NotImplementedError, "#{self.class} must implement #begin_transaction"
      end

      def commit
        raise NotImplementedError, "#{self.class} must implement #commit"
      end

      def rollback
        raise NotImplementedError, "#{self.class} must implement #rollback"
      end

      def close
        # Optional: Override if adapter needs cleanup
      end
    end
  end
end
