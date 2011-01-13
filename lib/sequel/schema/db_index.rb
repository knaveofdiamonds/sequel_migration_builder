module Sequel
  module Schema
    class DbIndex
      attr_accessor :name
      attr_reader :columns

      # Builds an Array of DbIndexes from the index hash returned by
      # Sequel::Database#indexes
      def self.build_from_hash(definitions)
        definitions.map {|name,attrs| new(name, attrs[:columns], attrs[:unique]) }
      end

      # Creates a new DbIndex definition.
      #
      # columns may be a single column name as a symbol, or an array
      # of column symbol names.
      #
      # Indexes are not unique by default.
      def initialize(name, columns, unique=false)
        @name = name.to_sym
        @columns = columns.kind_of?(Array) ? columns.clone : [columns]
        @unique = !! unique
      end

      # Returns true if this index is unique
      def unique?
        @unique
      end

      # Returns true if this index has more than one column.
      def multi_column?
        @columns.size > 1
      end

      # Returns the sequel migration statement to define an index in a
      # create_table block.
      def define_statement
        base_add_statement('index')
      end

      # Returns the sequel migration statement to add an index in an
      # alter_table block.
      def add_statement
        base_add_statement('add_index')
      end

      # Returns the sequel migration statement to remove an index in an
      # alter_table block.
      def drop_statement
        "drop_index #{columns_for_statement.inspect}, :name => #{name.inspect}"
      end

      # Indexes are equal if all their attributes are equal.
      def ==(other)
        other.kind_of?(self.class) &&
          @name == other.name && @columns == other.columns && @unique == other.unique?
      end
      alias :eql? :==
      
      def hash # :nodoc:
        @name.hash
      end

      private

      def columns_for_statement
        return columns.first unless multi_column?
        columns
      end
      
      def base_add_statement(keyword)
        parts = ["#{keyword} #{columns_for_statement.inspect}, :name => #{name.inspect}"]
        parts << ":unique => #{@unique.inspect}" if unique?
        parts.join(", ")
      end
    end
  end
end
