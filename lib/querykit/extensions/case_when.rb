# frozen_string_literal: true

require_relative '../case_builder'

module QueryKit
  # Extension module that adds CASE WHEN support to Query
  # Include this in Query to enable select_case functionality
  module CaseWhenExtension
    # Start a CASE expression and return the builder
    # The builder can be passed to select() like any other expression
    # @param column [String, nil] Optional column for simple CASE
    # @return [CaseBuilder] Builder for constructing CASE expression
    def select_case(column = nil)
      CaseBuilder.new(column)
    end
    
    # Override select to handle CaseBuilder objects
    def select(*columns)
      columns.flatten.each do |col|
        if col.is_a?(CaseBuilder)
          @selects << col.to_sql
          @bindings.concat(col.bindings)
        else
          @selects << col
        end
      end
      self
    end
  end
end
