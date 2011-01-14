require 'set'
require 'bigdecimal'

module Sequel
  module Schema
    DbColumn = Struct.new(:name, :column_type, :null, :default, :unsigned, :size, :elements, :single_primary_key)

    # A column in a database table.
    #
    # Responsible for generating all migration method calls used by
    # migration operations.
    #
    class DbColumn
      # Database column types that hold integers.
      INTEGER_TYPES = [:tinyint, :integer, :smallint, :mediumint, :bigint]

      # Database column types that hold fractional values.
      DECIMAL_TYPES = [:decimal, :float, :double, :real]

      # All numeric database column types.
      NUMERIC_TYPES = INTEGER_TYPES + DECIMAL_TYPES

      # Builds a DbColumn from a Hash of attribute values. Keys 
      # can be strings or symbols.
      #
      def self.build_from_hash(attrs={})
        self.new *members.map {|key| attrs[key] || attrs[key.to_sym] }
      end

      def initialize(*args)
        super
        normalize_default
      end
      
      # Returns a Sequel migration statement to define a column in a
      # create_table block.
      #
      def define_statement
        if single_primary_key
          ["primary_key #{name.inspect}, :type => #{column_type.inspect}", options].compact.join(", ")
        else
          ["#{column_type} #{name.inspect}", options].compact.join(", ")
        end
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

      # Returns an Set of attributes that are different between this
      # and another column.
      #
      def diff(other)
        { :null        => :boolean_attribute_different?,
          :unsigned    => :boolean_attribute_different?,
          :name        => :attribute_different?,
          :column_type => :attribute_different?,
          :elements    => :attribute_different?,
          :default     => :defaults_different?,
          :size        => :sizes_different? 
        }.select {|attribute, method| __send__(method, attribute, other) }.map {|a| a.first }.to_set
      end

      # Returns true if this column is numeric.
      #
      def numeric?
        NUMERIC_TYPES.include?(column_type)
      end

      private

      def attribute_different?(sym, other)
        other[sym] != self[sym]
      end

      def boolean_attribute_different?(sym, other)
        (!!other[sym]) != (!!self[sym])
      end

      def numeric_attribute_different?(sym, other)
        (self[sym] || 0) != (other[sym] || 0)
      end

      def sizes_different?(_, other)
        # Null size indicates 'lack of interest' in the size
        size && other.size && other.size != size
      end

      def defaults_different?(_, other)
        # Complicated by dealing with database defaults if the column
        # does not allow null values.
        if null == true || other.null == true
          attribute_different?(:default, other)
        elsif numeric? && other.numeric?
          numeric_attribute_different?(:default, other)
        else
          ! (default.blank? && other.default.blank?) && other.default != default
        end
      end

      def change_options
        opts = OptionBuilder.new

        opts.set :default, default
        # seems odd, but we only want to output if unsigned is a true
        # boolean, not if it is nil.
        opts.set :unsigned, unsigned if numeric? && (unsigned == true || unsigned == false)
        opts.set :size, size         if size
        opts.set :elements, elements if elements
        
        opts.render
      end

      def options
        opts = OptionBuilder.new
        
        opts.set :null, !!null       if null != true || column_type == :timestamp
        opts.set :default, default   if default || column_type == :timestamp
        opts.set :unsigned, true     if numeric? && unsigned
        opts.set :size, size         if size
        opts.set :elements, elements if elements

        opts.render
      end

      def normalize_default
        if DECIMAL_TYPES.include?(column_type) && ! self[:default].nil?
          self.default = BigDecimal(self[:default].to_s)
        end
      end
      
      # Formats column options in a Sequel migration
      class OptionBuilder
        def initialize
          @opts = []
        end
        
        # Sets column option name to a value.
        def set(name, value)
          @opts << "#{name.inspect} => #{value.inspect}"
        end
        
        # Renders the column option hash in a pretty format.
        def render
          @opts.join(", ") unless @opts.empty?
        end
      end
    end
  end
end
