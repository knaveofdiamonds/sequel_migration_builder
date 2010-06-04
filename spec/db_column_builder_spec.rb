require File.dirname(__FILE__) + "/spec_helper"

describe "A hash in the array returned by Sequel::Schema::DbColumnBuilder#parse_sequel_schema" do
  before :each do
    @parser = Sequel::Schema::DbColumnBuilder.new
    @schema = [[:example_column, 
                { :type => :integer, 
                  :default => "1", 
                  :ruby_default => 1, 
                  :primary_key => false, 
                  :db_type => "int(11)", 
                  :allow_null => true   }]]
  end

  it "should contain the :name of the column" do
    @parser.parse_sequel_schema(@schema).first.name.should == :example_column
  end
  
  it "should contain the ruby_default as the :default" do
    @parser.parse_sequel_schema(@schema).first.default.should == 1
  end
  
  it "should contain whether the column can be :null" do
    @parser.parse_sequel_schema(@schema).first.null.should == true
  end
  
  it "should have a type of :integer given a int column" do
    set_db_type "int(11)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :integer
  end

  it "should have a type of :boolean given a tinyint(1) column" do
    set_db_type "tinyint(1)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :boolean
  end

  it "should have a type of :tinyint given a tinyint column" do
    set_db_type "tinyint(4)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :tinyint
  end

  it "should have a type of :smallint given a smallint column" do
    set_db_type "smallint(5)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :smallint
  end

  it "should have a type of :mediumint given a mediumint column" do
    set_db_type "mediumint(5)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :mediumint
  end

  it "should have a type of :bigint given a bigint column" do
    set_db_type "bigint(10)"
    @parser.parse_sequel_schema(@schema).first.column_type.should == :bigint
  end

  it "should contain a :size attribute for text-like columns" do
    set_db_type "varchar(20)", :string
    @parser.parse_sequel_schema(@schema).first.size.should == 20
  end

  it "should contain :unsigned false if a numeric column is not unsigned" do
    set_db_type "int(10)"
    @parser.parse_sequel_schema(@schema).first.unsigned.should == false
  end

  it "should contain :unsigned true if a numeric column is unsigned" do
    set_db_type "int(10) unsigned"
    @parser.parse_sequel_schema(@schema).first.unsigned.should == true
  end

  it "should contain the elements of an enum column" do
    set_db_type "enum('foo','bar')"
    @parser.parse_sequel_schema(@schema).first.elements.should == ['foo', 'bar']
  end
  
  def set_db_type(type, ruby_type=nil)
    @schema.first.last.merge!(:db_type => type)
    @schema.first.last.merge!(:type => ruby_type) if ruby_type
  end
end
