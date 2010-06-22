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
        result = {}
        @db.tables.each do |table_name|
          result[table_name] = {:columns => parse_table_schema(@db.schema(table_name))}
        end
        result
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
                                   :unsigned    => extract_unsigned(column),
                                   :size        => extract_size(column, type),
                                   :elements    => extract_enum_elements(column, type))
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

      def extract_unsigned(column)
        column.last[:db_type].include?(" unsigned") if column.last[:type] == :integer
      end

      def extract_size(column, type)
        return unless column.last[:type] == :string || type == :decimal

        match = column.last[:db_type].match(/\(([0-9, ]+)\)/)
        if match && match[1]
          n = match[1].split(/\s*,\s*/).map {|i| i.to_i }
          n.size == 1 ? n.first : n
        end
      end

      def extract_enum_elements(column, type)
        return unless type == :enum

        match = column.last[:db_type].match(/\(([^)]+)\)/)
        eval('[' + match[1] + ']') if match[1]
      end
    end
  end
end
