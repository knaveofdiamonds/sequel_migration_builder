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
        dropped_columns = db_columns.keys - new_column_names

        operations += dropped_columns.map do |name| 
          DropColumn.new(db_columns[name])
        end

        db_indexes = db_table[:indexes] || {}
        new_indexes = new_table[:indexes] || {}

        operations += (db_indexes.keys - new_indexes.keys).reject do |index_name|
          db_indexes[index_name][:columns].size == 1 && dropped_columns.include?(db_indexes[index_name][:columns].first)
        end.map do |index_name|
          DropIndex.new(index_name, 
                        db_indexes[index_name][:columns],
                        db_indexes[index_name][:unique])
        end

        operations += (new_indexes.keys - db_indexes.keys).map do |index_name|
          AddIndex.new(index_name, 
                       new_indexes[index_name][:columns],
                       new_indexes[index_name][:unique])
        end

        operations
      end
      
      # Returns an array of operations to change the current database
      # column to be like the defined column.
      #
      def self.build_column_operations(db_column, new_column)
        result = []
        
        diffs = db_column.diff(new_column)
        result << :change_type_statement    if [:elements, :column_type, :size, :unsigned].any? {|sym| diffs.include?(sym) }
        # only need to explicitly set the default if we're not changing the column type.
        result << :change_default_statement if diffs.include?(:default) && result.empty?
        result << :change_null_statement    if diffs.include?(:null)
        
        result.map {|k| ChangeColumn.new(db_column, new_column, k) }
      end

      # Base alter table operation class. Each operation will return
      # Sequel::Migration statement(s) to alter the table.
      class Operation
        # Returns the statement for the up part of the migration
        attr_reader :up
        
        # Returns the statement for the down part of the operation
        attr_reader :down
      end

      # Changes a column.
      class ChangeColumn < Operation
        def initialize(old_column, new_column, statement)
          @up = new_column.__send__(statement)
          @down = old_column.__send__(statement)
        end
      end

      # Adds a column.
      class AddColumn < Operation
        def initialize(column)
          @up = column.add_statement
          @down = column.drop_statement
        end
      end

      # Drops a column.
      class DropColumn < Operation
        def initialize(column)
          @up = column.drop_statement
          @down = column.add_statement
        end
      end

      # Adds an index.
      class AddIndex < Operation
        def initialize(name, columns, unique)
          @up   = "add_index #{columns.inspect}, :name => #{name.inspect}"
          @up << ", :unique => true" if unique
          @down = "drop_index #{columns.inspect}, :name => #{name.inspect}"
        end
      end

      # Drops an index.
      class DropIndex < Operation
        def initialize(name, columns, unique)
          @up = "drop_index #{columns.inspect}, :name => #{name.inspect}"
          @down = "add_index #{columns.inspect}, :name => #{name.inspect}"
          @down << ", :unique => true" if unique
        end
      end
    end
  end
end
