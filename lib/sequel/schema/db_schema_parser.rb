module Sequel
  module Schema
    # Builds an abstract representation of a database schema.
    #
    # Sample usage:
    #
    #     parser = DbSchemaParser.for_db( sequel_db_connection )
    #     parser.parse_db_schema 
    #     # => Returns an array of table definitions
    #
    class DbSchemaParser
      # Returns an appropriate schema parser for the database
      # connection.
      #
      def self.for_db(db)
        self.new(db)
      end

      # Parses the schema from a Sequel Database connection.
      #
      # Returns a hash of table representations.
      #
      # Example:
      #
      #    builder.parse_db_schema(db)
      #    # => {:table1 => { :columns => [ DbColumns ... ] }
      #          :table2 => { ... } }
      #
      def parse_db_schema
        @db.tables.inject({}) do |result, table_name|
          result[table_name] = {
            :indexes => @db.indexes(table_name),
            :columns => parse_table_schema(@db.schema(table_name))
          }
          result
        end
      end

      # Extracts an array of hashes representing the columns in the
      # table, given an Array of Arrays returned by DB.schema(:table).
      #
      def parse_table_schema(db_schema)
        db_schema.map do |column|
          type = parse_type(column.last[:db_type])
          DbColumn.build_from_hash(:name        => column.first,
                                   :default     => column.last[:ruby_default],
                                   :null        => column.last[:allow_null],
                                   :column_type => type,
                                   :unsigned    => extract_unsigned(column.last[:db_type], type),
                                   :size        => extract_size(column.last[:db_type], type),
                                   :elements    => extract_enum_elements(column.last[:db_type], type))
        end
      end

      protected

      # Creates a new schema parser for the given database
      # connection. Use for_db instead.
      #
      def initialize(db)
        @db = db
      end

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

      def extract_unsigned(db_type_string, type)
        return unless DbColumn::NUMERIC_TYPES.include?(type)
        db_type_string.include?(" unsigned")
      end

      def extract_size(db_type_string, type)
        return if DbColumn::INTEGER_TYPES.include?(type)

        match = db_type_string.match(/\(([0-9, ]+)\)/)
        if match && match[1]
          n = match[1].split(/\s*,\s*/).map {|i| i.to_i }
          n.size == 1 ? n.first : n
        end
      end

      def extract_enum_elements(db_type_string, type)
        return unless type == :enum

        match = db_type_string.match(/\(([^)]+)\)/)
        eval('[' + match[1] + ']') if match[1]
      end
    end
  end
end
