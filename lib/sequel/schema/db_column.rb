module Sequel
  module Schema
    DbColumn = Struct.new(:name, :column_type, :null, :default, :unsigned, :size, :elements)

    # A column in a database table.
    #
    # Responsible for generating all migration method calls used by
    # migration operations.
    #
    class DbColumn
      # Builds a DbColumn from a Hash of attribute values. Keys 
      # can be strings or symbols.
      #
      def self.build_from_hash(attrs={})
        new *members.map {|key| attrs[key] || attrs[key.to_sym] }
      end

      # Returns a Sequel migration statement to define a column in a
      # create_table block.
      #
      def define_statement
        ["#{column_type} #{name.inspect}", options].compact.join(", ")
      end

      # Returns a Sequel migration statement to remove the column.
      #
      def drop_statement
        "drop_column #{name.inspect}"
      end

      # Returns a Sequel migration statement to add the column to a
      # table in an alter_table block.
      #
      def add_statement
        ["add_column #{name.inspect}", column_type.inspect, options].compact.join(", ")
      end
      
      # Returns a Sequel migration statement to change whether a column
      # allows null values.
      #
      def change_null_statement
        "set_column_allow_null #{name.inspect}, #{(!!null).inspect}"
      end

      # Returns a Sequel migration statement to change a column's default
      # value.
      # 
      def change_default_statement
        "set_column_default #{name.inspect}, #{default.inspect}"
      end

      # Returns a Sequel migration statement to change the type of an
      # existing column. Null changes must be handled separately.
      #
      def change_type_statement
        ["set_column_type #{name.inspect}", column_type.inspect, change_options].compact.join(", ")
      end

      # Returns an Array of attributes that are different between this
      # and another column.
      #
      def diff(other)
        result = []
        result << :null if (!!other[:null]) != (!!self[:null])
        result << :unsigned if (!!other[:unsigned]) != (!!self[:unsigned])
        result << :name if other.name != name
        result << :column_type if other.column_type != column_type
        result << :default if defaults_different?(other)
        result << :size if size && other.size && other.size != size
        result << :elements if other.elements != elements
        result
      end

      def numeric?
        [:tinyint, :integer, :smallint, :mediumint, :bigint, :bigdecimal, :decimal, :float].include?(column_type)
      end

      private

      def defaults_different?(other)
        if null == true || other.null == true
          other.default != default
        elsif numeric? && other.numeric?
          (default || 0) != (other.default || 0)
        else
          ! (default.blank? && other.default.blank?) && other.default != default
        end
      end

      def change_options
        opts = []

        opts << ":default => #{default.inspect}"
        # seems odd, but we only want to output if unsigned is a true
        # boolean, not if it is nil.
        opts << ":unsigned => #{unsigned.inspect}" if unsigned == true || unsigned == false
        opts << ":size => #{size.inspect}"         if size
        opts << ":elements => #{elements.inspect}" if elements

        opts.join(", ") unless opts.empty?
      end

      def options
        opts = []

        opts << ":null => #{(!!null).inspect}"     if null != true || column_type == :timestamp
        opts << ":default => #{default.inspect}"   if default || column_type == :timestamp
        opts << ":unsigned => true"                if unsigned
        opts << ":size => #{size.inspect}"         if size
        opts << ":elements => #{elements.inspect}" if elements

        opts.join(", ") unless opts.empty?
      end
    end
  end
end
