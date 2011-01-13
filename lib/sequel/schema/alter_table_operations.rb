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

        db_indexes = Schema::DbIndex.build_from_hash(db_table[:indexes] || {})
        new_indexes = Schema::DbIndex.build_from_hash(new_table[:indexes] || {})
        
        operations += (db_indexes - new_indexes).map do |index|
          index.drop_statement unless index.columns.all? {|c| dropped_columns.include?(c) }
        end
        
        operations += (new_indexes - db_indexes).map do |index|
          index.add_statement          
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
    end
  end
end
