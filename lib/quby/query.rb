# frozen_string_literal: true

module Quby
  # Query class for building SQL SELECT statements.
  class Query
    attr_reader :table, :wheres, :selects, :joins, :orders, :groups, :limit_value, :offset_value
    attr_accessor :bindings

    # Initialize a new Query instance.
    def initialize(table = nil)
      @table = table
      @selects = []
      @wheres = []
      @joins = []
      @orders = []
      @groups = []
      @havings = []
      @limit_value = nil
      @offset_value = nil
      @bindings = []
      @distinct = false
      @unions = []
    end

    # Set the table
    def from(table)
      @table = table
      self
    end

    # SELECT clause
    def select(*columns)
      columns = ['*'] if columns.empty?
      @selects.concat(columns.flatten)
      self
    end

    # Set the query to return distinct results
    def distinct
      @distinct = true
      self
    end

    # WHERE clauses
    def where(column, operator = nil, value = nil)
      # Handle different argument patterns
      if column.is_a?(Hash)
        column.each { |k, v| where(k, '=', v) }
        return self
      end

      if value.nil? && !operator.nil?
        value = operator
        operator = '='
      end

      @wheres << { type: 'basic', column: column, operator: operator, value: value, boolean: 'AND' }
      @bindings << value unless value.nil?
      self
    end

    # Add an OR WHERE condition to the query.
    def or_where(column, operator = nil, value = nil)
      if value.nil? && !operator.nil?
        value = operator
        operator = '='
      end

      @wheres << { type: 'basic', column: column, operator: operator, value: value, boolean: 'OR' }
      @bindings << value unless value.nil?
      self
    end

    # WHERE IN clause
    def where_in(column, values)
      @wheres << { type: 'in', column: column, values: values, boolean: 'AND' }
      @bindings.concat(values)
      self
    end

    # WHERE NOT IN clause
    def where_not_in(column, values)
      @wheres << { type: 'not_in', column: column, values: values, boolean: 'AND' }
      @bindings.concat(values)
      self
    end

    # WHERE IS NULL / IS NOT NULL
    def where_null(column)
      @wheres << { type: 'null', column: column, boolean: 'AND' }
      self
    end

    # WHERE IS NOT NULL
    def where_not_null(column)
      @wheres << { type: 'not_null', column: column, boolean: 'AND' }
      self
    end

    # WHERE BETWEEN
    def where_between(column, min, max)
      @wheres << { type: 'between', column: column, min: min, max: max, boolean: 'AND' }
      @bindings << min << max
      self
    end

    # Raw WHERE clause
    def where_raw(sql, *bindings)
      @wheres << { type: 'raw', sql: sql, boolean: 'AND' }
      @bindings.concat(bindings)
      self
    end

    # WHERE EXISTS
    def where_exists(subquery)
      sql = subquery.is_a?(String) ? subquery : subquery.to_sql
      @wheres << { type: 'exists', sql: sql, boolean: 'AND' }
      @bindings.concat(subquery.bindings) if subquery.respond_to?(:bindings)
      self
    end

    # WHERE NOT EXISTS
    def where_not_exists(subquery)
      sql = subquery.is_a?(String) ? subquery : subquery.to_sql
      @wheres << { type: 'not_exists', sql: sql, boolean: 'AND' }
      @bindings.concat(subquery.bindings) if subquery.respond_to?(:bindings)
      self
    end

    # JOIN clauses
    def join(table, first, operator = nil, second = nil)
      if operator.nil?
        operator = '='
        second = first
      end
      @joins << { type: 'INNER', table: table, first: first, operator: operator, second: second }
      self
    end

    # LEFT JOIN
    def left_join(table, first, operator = nil, second = nil)
      if operator.nil?
        operator = '='
        second = first
      end
      @joins << { type: 'LEFT', table: table, first: first, operator: operator, second: second }
      self
    end

    # RIGHT JOIN
    def right_join(table, first, operator = nil, second = nil)
      if operator.nil?
        operator = '='
        second = first
      end
      @joins << { type: 'RIGHT', table: table, first: first, operator: operator, second: second }
      self
    end

    # CROSS JOIN
    def cross_join(table)
      @joins << { type: 'CROSS', table: table }
      self
    end

    # ORDER BY
    def order_by(column, direction = 'ASC')
      @orders << { column: column, direction: direction.upcase }
      self
    end

    # Set the query to order results in descending order
    def order_by_desc(column)
      order_by(column, 'DESC')
    end

    # GROUP BY
    def group_by(*columns)
      @groups.concat(columns.flatten)
      self
    end

    # HAVING
    def having(column, operator = nil, value = nil)
      if value.nil? && !operator.nil?
        value = operator
        operator = '='
      end

      @havings << { column: column, operator: operator, value: value, boolean: 'AND' }
      @bindings << value unless value.nil?
      self
    end

    # LIMIT and OFFSET
    def limit(value)
      @limit_value = value
      self
    end

    # Set the query offset
    def offset(value)
      @offset_value = value
      self
    end

    # Alias methods for offset and limit
    def skip(value)
      offset(value)
    end

    # Alias methods for offset and limit
    def take(value)
      limit(value)
    end

    # Pagination
    def page(page_number, per_page = 15)
      offset((page_number - 1) * per_page).limit(per_page)
    end

    # Aggregate shortcuts
    def count(column = '*')
      select("COUNT(#{column}) as count")
    end

    def avg(column)
      select("AVG(#{column}) as avg")
    end

    def sum(column)
      select("SUM(#{column}) as sum")
    end

    def min(column)
      select("MIN(#{column}) as min")
    end

    def max(column)
      select("MAX(#{column}) as max")
    end

    # UNION / UNION ALL
    def union(query)
      @unions << { type: 'UNION', query: query }
      self
    end

    def union_all(query)
      @unions << { type: 'UNION ALL', query: query }
      self
    end

    # Build SQL
    def to_sql
      raise "No table specified" unless @table

      sql = []
      sql << "SELECT"
      sql << "DISTINCT" if @distinct
      sql << (@selects.empty? ? '*' : @selects.join(', '))
      sql << "FROM #{@table}"

      # JOINs
      # JOINs
      @joins.each do |join|
        if join[:type] == 'CROSS'
          sql << "CROSS JOIN #{join[:table]}"
        else
          sql << "#{join[:type]} JOIN #{join[:table]} ON #{join[:first]} #{join[:operator]} #{join[:second]}"
        end
      end

      # WHERE
      unless @wheres.empty?
        sql << "WHERE"
        where_clauses = []
        @wheres.each_with_index do |where, index|
          clause = build_where_clause(where)
          if index == 0
            where_clauses << clause
          else
            where_clauses << "#{where[:boolean]} #{clause}"
          end
        end
        sql << where_clauses.join(' ')
      end

      # GROUP BY
      unless @groups.empty?
        sql << "GROUP BY #{@groups.join(', ')}"
      end

      # HAVING
      unless @havings.empty?
        sql << "HAVING"
        having_clauses = []
        @havings.each_with_index do |having, index|
          clause = "#{having[:column]} #{having[:operator]} ?"
          if index == 0
            having_clauses << clause
          else
            having_clauses << "#{having[:boolean]} #{clause}"
          end
        end
        sql << having_clauses.join(' ')
      end

      # ORDER BY
      unless @orders.empty?
        sql << "ORDER BY #{@orders.map { |o| "#{o[:column]} #{o[:direction]}" }.join(', ')}"
      end

      # LIMIT
      sql << "LIMIT #{@limit_value}" if @limit_value

      # OFFSET
      sql << "OFFSET #{@offset_value}" if @offset_value

      # Build main query
      main_sql = sql.join(' ')

      # UNION / UNION ALL
      unless @unions.empty?
        union_parts = [main_sql]
        @unions.each do |union|
          union_sql = union[:query].is_a?(String) ? union[:query] : union[:query].to_sql
          union_parts << "#{union[:type]} #{union_sql}"
          @bindings.concat(union[:query].bindings) if union[:query].respond_to?(:bindings)
        end
        return union_parts.join(' ')
      end

      main_sql
    end

    def to_s
      to_sql
    end

    private

    # Build individual WHERE clause
    def build_where_clause(where)
      case where[:type]
      when 'basic'
        "#{where[:column]} #{where[:operator]} ?"
      when 'in'
        placeholders = (['?'] * where[:values].size).join(', ')
        "#{where[:column]} IN (#{placeholders})"
      when 'not_in'
        placeholders = (['?'] * where[:values].size).join(', ')
        "#{where[:column]} NOT IN (#{placeholders})"
      when 'null'
        "#{where[:column]} IS NULL"
      when 'not_null'
        "#{where[:column]} IS NOT NULL"
      when 'between'
        "#{where[:column]} BETWEEN ? AND ?"
      when 'raw'
        where[:sql]
      when 'exists'
        "EXISTS (#{where[:sql]})"
      when 'not_exists'
        "NOT EXISTS (#{where[:sql]})"
      end
    end
  end
end
