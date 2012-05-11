require File.dirname(__FILE__) + "/spec_helper"

describe "Sequel::Schema::DbSchemaParser.for_db" do
  it "should return a DbSchemaParser" do
    Sequel::Schema::DbSchemaParser.for_db(stub(:database)).should \
      be_kind_of(Sequel::Schema::DbSchemaParser)
  end
end

describe "A hash in the array returned by Sequel::Schema::DbSchemaParser#parse_table_schema" do
  before :each do
    @parser = Sequel::Schema::DbSchemaParser.for_db(stub(:database))
    @schema = [[:example_column, 
                { :type => :integer, 
                  :default => "1", 
                  :ruby_default => 1, 
                  :primary_key => false, 
                  :db_type => "int(11)", 
                  :allow_null => true   }]]
  end

  it "should contain the :name of the column" do
    @parser.parse_table_schema(@schema).first.name.should == :example_column
  end
  
  it "should contain the ruby_default as the :default" do
    @parser.parse_table_schema(@schema).first.default.should == 1
  end
  
  it "should contain whether the column can be :null" do
    @parser.parse_table_schema(@schema).first.null.should == true
  end
  
  it "should contain a type of :integer given a int column" do
    set_db_type "int(11)"
    @parser.parse_table_schema(@schema).first.column_type.should == :integer
  end

  it "should contain a type of :boolean given a tinyint(1) column" do
    set_db_type "tinyint(1)"
    @parser.parse_table_schema(@schema).first.column_type.should == :boolean
  end

  it "should contain a type of :tinyint given a tinyint column" do
    set_db_type "tinyint(4)"
    @parser.parse_table_schema(@schema).first.column_type.should == :tinyint
  end

  it "should contain a type of :smallint given a smallint column" do
    set_db_type "smallint(5)"
    @parser.parse_table_schema(@schema).first.column_type.should == :smallint
  end

  it "should contain a type of :mediumint given a mediumint column" do
    set_db_type "mediumint(5)"
    @parser.parse_table_schema(@schema).first.column_type.should == :mediumint
  end

  it "should contain a type of :bigint given a bigint column" do
    set_db_type "bigint(10)"
    @parser.parse_table_schema(@schema).first.column_type.should == :bigint
  end

  it "should contain a :size attribute for text-like columns" do
    set_db_type "varchar(20)", :string
    @parser.parse_table_schema(@schema).first.size.should == 20
  end

  it "should contain a :size attribute for decimal columns" do
    set_db_type "decimal(14,5)"
    @parser.parse_table_schema(@schema).first.size.should == [14,5]
  end

  it "should contain a :size attribute for binary columns" do
    set_db_type "binary(16)", :blob
    @parser.parse_table_schema(@schema).first.size.should == 16
  end
  
  it "should contain :unsigned false if a numeric column is not unsigned" do
    set_db_type "int(10)"
    @parser.parse_table_schema(@schema).first.unsigned.should == false
  end

  it "should contain :unsigned true if an integer column is unsigned" do
    set_db_type "int(10) unsigned"
    @parser.parse_table_schema(@schema).first.unsigned.should == true
  end

  it "should contain :unsigned true if a decimal column is unsigned" do
    @schema = [[:example_column, 
                { :type => nil, 
                  :default => "1", 
                  :ruby_default => 1, 
                  :primary_key => false, 
                  :db_type => "decimal(10,2) unsigned", 
                  :allow_null => true   }]]

    @parser.parse_table_schema(@schema).first.unsigned.should == true
  end

  it "should not contain an :unsigned value if not a numeric column" do
    set_db_type "varchar(10)", :string
    @parser.parse_table_schema(@schema).first.unsigned.should == nil
  end

  it "should contain the elements of an enum column" do
    set_db_type "enum('foo','bar')"
    @parser.parse_table_schema(@schema).first.elements.should == ['foo', 'bar']
  end
  
  def set_db_type(type, ruby_type=nil)
    @schema.first.last.merge!(:db_type => type)
    @schema.first.last.merge!(:type => ruby_type) if ruby_type
  end
end

describe "Sequel::Schema::DbSchemaParser#parse_db_schema" do
  it "should extract a list of table definitions from a database" do
    mock_db = mock(:db)
    mock_db.should_receive(:tables).at_least(:once).and_return([:table1])
    mock_db.should_receive(:schema).with(:table1).and_return([])
    mock_db.should_receive(:indexes).with(:table1, :partial => true)

    @parser = Sequel::Schema::DbSchemaParser.for_db(mock_db)
    @parser.parse_db_schema.keys.should == [:table1]
  end
end

### Regression tests

describe "Parsing a text column" do
  it "should not raise an error because it does not have a size" do
    parser = Sequel::Schema::DbSchemaParser.for_db(stub(:database))
    schema = [[:example_column, 
               { :type => :string, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "text", 
                 :allow_null => true   }]]

    lambda { parser.parse_table_schema(schema) }.should_not raise_error
  end
end

describe "Parsing an enum column" do
  it "should not raise an error when enum values contains brackets" do
    parser = Sequel::Schema::DbSchemaParser.for_db(stub(:database))
    schema = [[:example_column, 
               { :type => :enum, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "enum('foo (bar)', 'baz')",
                 :allow_null => true   }]]

    lambda { parser.parse_table_schema(schema) }.should_not raise_error(SyntaxError)
  end

  it "should correctly parse elements with escaped '' in them" do
    parser = Sequel::Schema::DbSchemaParser.for_db(stub(:database))
    schema = [[:example_column, 
               { :type => :enum, 
                 :default => nil, 
                 :ruby_default => nil, 
                 :primary_key => false, 
                 :db_type => "enum('don''t')",
                 :allow_null => true   }]]

    
    parser.parse_table_schema(schema).first.elements.should == ["don't"]
  end
end
