module Sequel
  module Schema
    module AlterTableOperations
      
      # Returns an array of operations to change the current database
      # table to be like the defined table.
      #
      def self.build(db_table, new_table)
        db_columns = db_table[:columns].inject({}) {|hsh, column| hsh[column.name] = column; hsh }

        operations = new_table[:columns].map do |column|
          if db_columns[column.name]
            build_column_operations db_columns[column.name], column
          else
            AddColumn.new(column)
          end
        end.flatten

        new_column_names = new_table[:columns].map {|c| c.name }
        operations + (db_columns.keys - new_column_names).map {|column| DropColumn.new(column) }
      end
      
      # Returns an array of operations to change the current database
      # column to be like the defined column.
      #
      def self.build_column_operations(db_column, new_column)
        result = []
        
        diffs = db_column.diff(new_column)
        result << :change_type_statement    if [:column_type, :size, :unsigned].any? {|sym| diffs.include?(sym) }
        # only need to explicitly set the default if we're not changing the column type.
        result << :change_default_statement if diffs.include?(:default) && result.empty?
        result << :change_null_statement    if diffs.include?(:null)
        
        result.map {|k| ChangeColumn.new(db_column, new_column, k) }
      end

      # Changes a column.
      class ChangeColumn
        def initialize(old_column, new_column, statement)
          @old_column, @new_column = old_column, new_column
          @statement_method = statement
        end

        def up
          @new_column.__send__(@statement_method)
        end

        def down
          @old_column.__send__(@statement_method)
        end
      end

      # Adds a column.
      class AddColumn
        def initialize(column)
          @column = column
        end

        def up
          @column.add_statement
        end

        def down
          @column.drop_statement
        end
      end

      # Drops a column.
      class DropColumn
        def initialize(column)
          @column = column
        end

        def up
          @column.drop_statement
        end

        def down
          @column.add_statement
        end
      end
    end
  end
end
