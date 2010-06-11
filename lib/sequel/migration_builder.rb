require 'sequel/schema/db_column'
require 'sequel/schema/db_schema_parser'
require 'sequel/schema/migration_operations'

module Sequel
  class MigrationBuilder
    INDENT_SPACES = '  '

    def initialize(db)
      @db = db
      @indent = 0
      @result = []
    end

    def generate_migration(tables)
      return if tables.empty?
      result.clear

      add_line "Sequel.migration do"
      indent do
        generate_up(tables)
        generate_down(tables)
      end
      add_line "end\n"

      result.join("\n")
    end

    private

    def generate_up(tables)
      i = 0 

      add_line "up do"
      table_names(tables).each do |table_name|
        i += 1
        table = tables[table_name]
        indent do
          unless @db.table_exists?(table_name)
            add_line "create_table #{table_name.inspect} do"
            indent do
              table[:columns].each do |column|
                add_line Schema::DbColumn.build_from_hash(column).define_statement
              end
            end
            add_line "end"
          end
          add_blank_line unless i == tables.size
        end
      end        
      add_line "end"
      add_blank_line
    end

    def generate_down(tables)
      add_line "down do"
      indent do
        table_names(tables).reverse.each do |table_name| 
          add_line "drop_table #{table_name.inspect}" unless @db.table_exists?(table_name)
        end
      end
      add_line "end"
    end

    attr_reader :result

    def table_names(tables)
      tables.keys.map {|n| n.to_s }.sort.map {|n| n.to_sym }
    end

    def indent
      @indent += 1
      yield
      @indent -= 1
    end

    def add_line(line)
      @result << (INDENT_SPACES * @indent + line)
    end

    def add_blank_line
      @result << ''
    end
  end
end
