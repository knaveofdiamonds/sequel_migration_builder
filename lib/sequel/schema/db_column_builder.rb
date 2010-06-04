module Sequel
  module Schema
    # Parses an array of column definitions, as returned by
    # DB.schema(:table).
    #
    class DbColumnBuilder

      # Extracts an array of hashes representing the columns in the
      # table, given an Array of Arrays returned by DB.schema(:table).
      #
      def parse_sequel_schema(db_schema)
        db_schema.map do |column|
          c = DbColumn.new
          c.name        = column.first
          c.default     = column.last[:ruby_default]
          c.null        = column.last[:allow_null]
          c.column_type = parse_type(column.last[:db_type])
          c.unsigned    = column.last[:db_type].include?(" unsigned")
          c.size        = extract_size(column) if column.last[:type] == :string
          c.elements    = extract_enum_elements(column) if c.column_type == :enum
          c
        end
      end

      protected

      # Returns a type symbol for a given db_type string, suitable for
      # use in a Sequel migration.
      #
      # Examples:
      #
      #    parse_type("int(11)")     # => :integer
      #    parse_type("varchar(20)") # => :varchar
      #
      def parse_type(type)
        case type
        when /^int/          then :integer
        when /^tinyint\(1\)/ then :boolean
        when /^([^(]+)/      then $1.to_sym
        end
      end

      private

      def extract_size(column)
        match = column.last[:db_type].match(/\((\d+)\)/)
        match[1].to_i if match[1]
      end

      def extract_enum_elements(column)
        match = column.last[:db_type].match(/\(([^)]+)\)/)
        eval('[' + match[1] + ']') if match[1]
      end
    end
  end
end
