module Sequel
  module Schema
    DbColumn = Struct.new(:name, :column_type, :null, :default, :unsigned, :size, :elements)

    # A column in a database table.
    #
    # Responsible for generating all migration method calls used by
    # migration operations.
    #
    class DbColumn
      # Returns a Sequel Migration statement to define a column in a
      # create_table block.
      #
      def define_statement
        ["#{column_type} #{name.inspect}", options].compact.join(", ")
      end

      # Returns a Sequel Migration statement to remove the column.
      #
      def drop_statement
        "drop_column #{name.inspect}"
      end

      # Returns a Sequel Migration statement to add the column to a
      # table in an alter_table block.
      #
      def add_statement
        ["add_column #{name.inspect}", column_type.inspect, add_options].compact.join(", ")
      end
      
      # Returns a Sequel Migration statement to change whether a column
      # allows null values.
      #
      def change_null_statement
        "set_column_allow_null #{name.inspect}, #{null.inspect}"
      end

      # Returns a Sequel Migration statement to change a column's default
      # value.
      # 
      def change_default_statement
        "set_column_default #{name.inspect}, #{default.inspect}"
      end

      # Returns an Array of attributes that are different between this
      # and another column.
      #
      def diff(other)
        result = []
        each_pair {|key, value| result << key if other[key] != value }
        result
      end

      private

      def add_options
        opts = []

        opts << ":default => #{default.inspect}"
        opts << ":unsigned => #{unsigned}"
        opts << ":size => #{size.inspect}"         if size
        opts << ":elements => #{elements.inspect}" if elements

        opts.join(", ") unless opts.empty?
      end

      def options
        opts = []

        opts << ":null => false"                   if null == false
        opts << ":default => #{default.inspect}"   if default
        opts << ":unsigned => true"                if unsigned
        opts << ":size => #{size.inspect}"         if size
        opts << ":elements => #{elements.inspect}" if elements

        opts.join(", ") unless opts.empty?
      end
    end
  end
end
