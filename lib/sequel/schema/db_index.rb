module Sequel
  module Schema
    class DbIndex
      attr_accessor :name
      attr_reader :columns

      # Builds an Array of indexes from the index hash returned by
      # Sequel::Database#indexes
      def self.build_from_hash(definitions)
        definitions.map {|name,attrs| new(name, attrs[:columns], attrs[:unique]) }
      end
      
      def initialize(name, columns, unique=false)
        @name = name.to_sym
        @columns = columns.kind_of?(Array) ? columns.clone : [columns]
        @unique = unique
      end

      def unique?
        !! @unique
      end

      def multi_column?
        @columns.size > 1
      end
      
      def define_statement
        base_add_statement('index')
      end

      def add_statement
        base_add_statement('add_index')
      end

      def drop_statement
        "drop_index #{columns_for_statement.inspect}, :name => #{name.inspect}"
      end

      # Returns true if this index has the same name as the other index.
      def same?(other)
        name == other.name
      end
      
      # Indexes are equal if all their attributes are equal.
      def ==(other)
        other.kind_of?(self.class) &&
          @name == other.name && @columns == other.columns && @unique == other.unique?
      end
      alias :eql? :==
      
      def hash
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
