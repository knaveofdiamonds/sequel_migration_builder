require 'sequel/schema/db_column'
require 'sequel/schema/db_schema_parser'
require 'sequel/schema/migration_operations'

module Sequel
  class MigrationBuilder
    INDENT_SPACES = '  '

    def initialize(db)
      @db = db
      @db_tables = Schema::DbSchemaParser.for_db(db).parse_db_schema
      @db_table_names = @db.tables
      @indent = 0
      @result = []
    end

    def generate_migration(tables)
      return if tables.empty? && @db_tables.empty?
      result.clear

      add_line "Sequel.migration do"
      indent do
        generate_up(tables)
        generate_down(tables)
      end
      add_line "end\n"

      result.join("\n")
    end

    def generate_up(tables)
      current_tables, new_tables = table_names(tables).partition do |table_name| 
        @db_table_names.include?(table_name)
      end

      add_line "up do"
      create_new_tables(new_tables, tables)
      add_line "end"
      add_blank_line
    end

    def generate_down(tables)
      current_tables, new_tables = table_names(tables).partition do |table_name| 
        @db_table_names.include?(table_name)
      end

      add_line "down do"
      indent do
        new_tables.reverse.each {|table_name| add_line "drop_table #{table_name.inspect}" }
      end
      add_line "end"
    end

    def create_new_tables(new_tables, tables)
      i = 0
      new_tables.each do |table_name|
        i += 1
        indent { create_table_statement table_name, tables[table_name] }
        add_blank_line unless i == tables.size
      end
    end

    def create_table_statement(table_name, table)
      add_line "create_table #{table_name.inspect} do"
      indent do
        table[:columns].map {|c| Schema::DbColumn.build_from_hash(c) }.each do |column|
          add_line column.define_statement
        end
        if table[:primary_key]
          add_blank_line
          add_line "primary_key #{table[:primary_key].inspect}"
        end
      end
      add_line "end"
    end

    private

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
