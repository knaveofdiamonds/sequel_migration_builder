module Sequel
  module Schema
    module MigrationOperations
      
      def self.build(db_column, new_column)
        result = []
        
        diffs = db_column.diff(new_column)        
        result << :change_type_statement    if [:type, :size, :unsigned].any? {|sym| diffs.include?(sym) }
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
