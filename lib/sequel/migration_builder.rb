require 'sequel/extensions/blank'
require 'sequel/schema/db_column'
require 'sequel/schema/db_schema_parser'
require 'sequel/schema/alter_table_operations'

module Sequel
  # Generates a Sequel migration to bring a database inline with an
  # abstract schema.
  #
  class MigrationBuilder
    INDENT_SPACES = '  '

    # Creates a migration builder for the given database.
    #
    def initialize(db)
      @db = db
      @db_tables = Schema::DbSchemaParser.for_db(db).parse_db_schema
      @db_table_names = @db.tables
      @indent = 0
      @result = []
    end

    # Generates a string of ruby code to define a sequel
    # migration, based on the differences between the database schema
    # of this MigrationBuilder and the tables passed.
    #
    def generate_migration(tables)
      return if tables.empty? && @db_tables.empty?
      result.clear

      add_line "Sequel.migration do"
      indent do
        generate_migration_body(tables)
      end
      add_line "end\n"

      result.join("\n")
    end

    # Generates the 'change' block of the migration.
    #
    def generate_migration_body(tables)
      current_tables, new_tables = table_names(tables).partition do |table_name| 
        @db_table_names.include?(table_name)
      end

      add_line "change do"
      create_new_tables(new_tables, tables)
      alter_tables(current_tables, tables, :up)
      add_line "end"
    end

    # Generates any create table statements for new tables.
    #
    def create_new_tables(new_table_names, tables)
      each_table(new_table_names, tables) do |table_name, table, last_table|
        create_table_statement table_name, table
        add_blank_line unless last_table
      end
    end

    # Generates any drop table statements for new tables.
    #
    def drop_new_tables(new_table_names)
      indent do
        new_table_names.reverse.each {|table_name| add_line "drop_table #{table_name.inspect}" }
      end
    end

    # Generates any alter table statements for current tables.
    #
    def alter_tables(current_table_names, tables, direction)
      each_table(current_table_names, tables) do |table_name, table, last_table|
        hsh = table.dup
        hsh[:columns] = hsh[:columns].map {|c| Schema::DbColumn.build_from_hash(c) }
        operations = Schema::AlterTableOperations.build(@db_tables[table_name], hsh)
        unless operations.empty?
          alter_table_statement table_name, operations, direction
          add_blank_line unless last_table
        end
      end
    end

    # Generates an individual alter table statement.
    #
    def alter_table_statement(table_name, operations, direction)
      add_line "alter_table #{table_name.inspect} do"
      indent do
        operations.map {|op| op.__send__(direction) }.compact.each {|op| add_line op }
      end
      add_line "end"
    end

    # Generates an individual create_table statement.
    #
    def create_table_statement(table_name, table)
      add_line "create_table #{table_name.inspect}#{pretty_hash(table[:table_options])} do"
      indent do
        table[:primary_key] = [table[:primary_key]] if table[:primary_key].kind_of?(Symbol)
        table[:columns].each do |c| 
          column = Schema::DbColumn.build_from_hash(c)
          if table[:primary_key] && table[:primary_key].size == 1 && table[:primary_key].first == column.name
            column.single_primary_key = true
          end
          add_line column.define_statement
        end
        if table[:indexes]
          add_blank_line
          table[:indexes].each do |name, options|
            opts = options.clone
            columns = opts.delete(:columns)
            add_line "index #{columns.inspect}, :name => #{name.to_sym.inspect}#{pretty_hash(opts)}"
          end
        end
        if table[:primary_key] && table[:primary_key].size > 1
          add_blank_line
          add_line "primary_key #{table[:primary_key].inspect}"
        end
      end
      add_line "end"
    end

    private

    attr_reader :result

    def each_table(table_names, tables)
      i = 0
      indent do
        table_names.each do |table_name|
          i += 1
          yield table_name, tables[table_name], i == tables.size
        end
      end
    end

    # Returns a string representing a hash as ':foo => :bar'
    # rather than '{:foo=.:bar}'
    def pretty_hash(hash)
      ", " + hash.inspect.gsub(/^\{|\}$/,'').gsub("=>", " => ") if hash && ! hash.empty?
    end

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
