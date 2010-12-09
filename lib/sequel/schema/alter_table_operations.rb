module Sequel
  module Schema
    class AlterTableOperations
      # Returns an array of operations to change the current database
      # table to be like the defined table.
      #
      def self.build(db_table, new_table)
        new.build(db_table, new_table)
      end

      def build(db_table, new_table)
        db_columns = db_table[:columns].inject({}) {|hsh, column| hsh[column.name] = column; hsh }
        new_column_names = new_table[:columns].map {|c| c.name }
        dropped_columns = db_columns.keys - new_column_names

        operations = new_table[:columns].map do |column|
          if db_columns[column.name]
            build_column_operations db_columns[column.name], column
          else
            column.add_statement
          end
        end.flatten

        operations += dropped_columns.map do |name| 
          db_columns[name].drop_statement
        end

        db_indexes = db_table[:indexes] || {}
        new_indexes = new_table[:indexes] || {}

        operations += (db_indexes.keys - new_indexes.keys).map do |index_name|
          dropped_column = db_indexes[index_name][:columns].size == 1 && dropped_columns.include?(db_indexes[index_name][:columns].first)

          drop_index(index_name, 
                     db_indexes[index_name][:columns],
                     ! dropped_column)
        end
        
        operations += (new_indexes.keys - db_indexes.keys).map do |index_name|
          if new_indexes[index_name][:columns].kind_of?(Symbol)
            dropped_column = dropped_columns.include?(new_indexes[index_name][:columns])
          else
            dropped_column = new_indexes[index_name][:columns].size == 1 && dropped_columns.include?(new_indexes[index_name][:columns].first)
          end
          
          add_index(index_name, new_indexes[index_name][:columns],
                    new_indexes[index_name][:unique])
          
        end
        
        operations        
      end
      
      # Returns an array of operations to change the current database
      # column to be like the defined column.
      #
      def build_column_operations(db_column, new_column)
        result = []
        
        diffs = db_column.diff(new_column)
        result << :change_type_statement    if [:elements, :column_type, :size, :unsigned].any? {|sym| diffs.include?(sym) }
        # only need to explicitly set the default if we're not changing the column type.
        result << :change_default_statement if diffs.include?(:default) && result.empty?
        result << :change_null_statement    if diffs.include?(:null)
        
        result.map {|statement| new_column.__send__(statement) }
      end
      
      def add_index(name, columns, unique)
        stmt = "add_index #{columns.inspect}, :name => #{name.inspect}"
        stmt << ", :unique => true" if unique
      end
      
      def drop_index(name, columns, include_drop_index=true)
        "drop_index #{columns.inspect}, :name => #{name.inspect}" if include_drop_index
      end
    end
  end
end
