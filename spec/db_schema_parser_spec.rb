require File.dirname(__FILE__) + "/spec_helper"

describe "Sequel::Schema::DbSchemaParser.for_db" do
  it "should return a DbSchemaParser" do
    expect(Sequel::Schema::DbSchemaParser.for_db(double(:database))).
      to be_kind_of(Sequel::Schema::DbSchemaParser)
  end
end

describe "A hash in the array returned by Sequel::Schema::DbSchemaParser#parse_table_schema" do
  before :each do
    @parser = Sequel::Schema::DbSchemaParser.for_db(double(:database))
    @schema = [[:example_column, 
                { :type => :integer, 
                  :default => "1", 
                  :ruby_default => 1, 
                  :primary_key => false, 
                  :db_type => "int(11)", 
                  :allow_null => true   }]]
  end

  it "should contain the :name of the column" do
    expect(@parser.parse_table_schema(@schema).first.name).to eql(:example_column)
  end
  
  it "should contain the ruby_default as the :default" do
    expect(@parser.parse_table_schema(@schema).first.default).to eql(1)
  end

  it "should contain the ruby_default as the :default when that default is false" do
    @schema.first.last.merge!(:default => "false", :ruby_default => false)
    expect(@parser.parse_table_schema(@schema).first.default).to eql(false)
  end
  
  it "should contain whether the column can be :null" do
    expect(@parser.parse_table_schema(@schema).first.null).to eql(true)
  end
  
  it "should contain a type of :integer given a int column" do
    set_db_type "int(11)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:integer)
  end

  it "should contain a type of :boolean given a tinyint(1) column" do
    set_db_type "tinyint(1)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:boolean)
  end

  it "should contain a type of :tinyint given a tinyint column" do
    set_db_type "tinyint(4)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:tinyint)
  end

  it "should contain a type of :smallint given a smallint column" do
    set_db_type "smallint(5)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:smallint)
  end

  it "should contain a type of :mediumint given a mediumint column" do
    set_db_type "mediumint(5)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:mediumint)
  end

  it "should contain a type of :bigint given a bigint column" do
    set_db_type "bigint(10)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:bigint)
  end

  it "should contain a type of :decimal given a numeric(x,y) column" do
    set_db_type "numeric(3,4)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:decimal)
  end

  it "should contain a type of :char given a character column" do
    set_db_type "character(3)"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:char)
  end

  it "should contain a :size attribute for text-like columns" do
    set_db_type "varchar(20)", :string
    expect(@parser.parse_table_schema(@schema).first.size).to eql(20)
  end

  it "should contain a :size attribute for decimal columns" do
    set_db_type "decimal(14,5)"
    expect(@parser.parse_table_schema(@schema).first.size).to eql([14,5])
  end

  it "should contain a :size attribute for binary columns" do
    set_db_type "binary(16)", :blob
    expect(@parser.parse_table_schema(@schema).first.size).to eql(16)
  end
  
  it "should contain :unsigned false if a numeric column is not unsigned" do
    set_db_type "int(10)"
    expect(@parser.parse_table_schema(@schema).first.unsigned).to eql(false)
  end

  it "should contain :unsigned true if an integer column is unsigned" do
    set_db_type "int(10) unsigned"
    expect(@parser.parse_table_schema(@schema).first.unsigned).to eql(true)
  end

  it "should contain :unsigned true if a decimal column is unsigned" do
    @schema = [[:example_column, 
                { :type => nil, 
                  :default => "1", 
                  :ruby_default => 1, 
                  :primary_key => false, 
                  :db_type => "decimal(10,2) unsigned", 
                  :allow_null => true   }]]

    expect(@parser.parse_table_schema(@schema).first.unsigned).to eql(true)
  end

  it "should not contain an :unsigned value if not a numeric column" do
    set_db_type "varchar(10)", :string
    expect(@parser.parse_table_schema(@schema).first.unsigned).to eql(nil)
  end

  it "should contain the elements of an enum column" do
    set_db_type "enum('foo','bar')"
    expect(@parser.parse_table_schema(@schema).first.elements).to eql(['foo', 'bar'])
  end
  
  it "should be a varchar if the the db type is character varying" do
    set_db_type "character varying"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:varchar)
  end

  it "should be a timestamp if the the db type is a timestamp without time zone" do
    set_db_type "timestamp without time zone"
    expect(@parser.parse_table_schema(@schema).first.column_type).to eql(:timestamp)
  end

  it "should not have a default for postgres identity columns" do
    @schema.first.last.merge!(:default => "\"identity\"(123,0)",
                              :ruby_default => nil)
    expect(@parser.parse_table_schema(@schema).first.default).to be_nil   
  end

  def set_db_type(type, ruby_type=nil)
    @schema.first.last.merge!(:db_type => type)
    @schema.first.last.merge!(:type => ruby_type) if ruby_type
  end
end

describe "Sequel::Schema::DbSchemaParser#parse_db_schema" do
  it "should extract a list of table definitions from a database" do
    mock_db = double(:db)
    expect(mock_db).to receive(:tables).at_least(:once).and_return([:table1])
    expect(mock_db).to receive(:schema).with(:table1).and_return([])
    expect(mock_db).to receive(:indexes).with(:table1, :partial => true)

    @parser = Sequel::Schema::DbSchemaParser.for_db(mock_db)
    expect(@parser.parse_db_schema.keys).to eql([:table1])
  end
end

### Regression tests

describe "Parsing a text column" do
  it "should not raise an error because it does not have a size" do
    parser = Sequel::Schema::DbSchemaParser.for_db(double(:database))
    schema = [[:example_column, 
               { :type => :string, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "text", 
                 :allow_null => true   }]]

    expect { parser.parse_table_schema(schema) }.not_to raise_error
  end
end

describe "Parsing an enum column" do
  it "should not raise an error when enum values contains brackets" do
    parser = Sequel::Schema::DbSchemaParser.for_db(double(:database))
    schema = [[:example_column, 
               { :type => :enum, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "enum('foo (bar)', 'baz')",
                 :allow_null => true   }]]

    expect { parser.parse_table_schema(schema) }.not_to raise_error
  end

  it "should correctly parse elements with escaped '' in them" do
    parser = Sequel::Schema::DbSchemaParser.for_db(double(:database))
    schema = [[:example_column, 
               { :type => :enum, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "enum('don''t')",
                 :allow_null => true   }]]

    
    expect(parser.parse_table_schema(schema).first.elements).to eql(["don't"])
  end
end
