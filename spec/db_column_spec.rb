require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::Schema::DbColumn do

  before :each do
    @column = Sequel::Schema::DbColumn.new(:foo, :integer, false, 10, true, 10, nil)
  end

  it "should return a #define_statement" do
    @column.define_statement.should == "integer :foo, :null => false, :default => 10, :unsigned => true, :size => 10"
  end
  
  it "should return a #drop_statement" do
    @column.drop_statement.should == "drop_column :foo"
  end

  it "should return an #add_statement" do
    @column.add_statement.should == "add_column :foo, :integer, :null => false, :default => 10, :unsigned => true, :size => 10"
  end

  it "should return a #change_null statement" do
    @column.change_null_statement.should == "set_column_allow_null :foo, false"
  end

  it "should return a #change_default statement" do
    @column.change_default_statement.should == "set_column_default :foo, 10"
  end

  it "should return a #change_type statement" do
    @column.change_type_statement.should == "set_column_type :foo, :integer, :default => 10, :unsigned => true, :size => 10"
  end

  it "should be diffable with another DbColumn" do
    other = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    @column.diff(other).should == [:column_type].to_set

    other = Sequel::Schema::DbColumn.new(:foo, :integer, true, 11, true, 10, nil)
    @column.diff(other).should == [:null, :default].to_set
  end

  it "should not consider allowing null being nil different from false" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, nil, 10, true, 10, nil)
    a.diff(b).should be_empty
    b.diff(a).should be_empty
  end

  it "should not consider size to be different if one of the sizes is nil" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, nil, nil)
    a.diff(b).should be_empty
    b.diff(a).should be_empty
  end

  it "should not consider 0 to be different from null if the column does not allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 0, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, nil, true, nil, nil)
    a.diff(b).should be_empty
    b.diff(a).should be_empty
  end

  it "should consider 0 to be different from null if the column does allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, true, 0, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, true, nil, true, nil, nil)
    a.diff(b).should == [:default].to_set
    b.diff(a).should == [:default].to_set
  end

  it "should consider 1 to be different from null" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 1, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, nil, true, nil, nil)
    a.diff(b).should == [:default].to_set
    b.diff(a).should == [:default].to_set
  end

  it "should not consider '' to be different from null if the column does not allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :varchar, false, '', true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :varchar, false, nil, true, nil, nil)
    a.diff(b).should be_empty
    b.diff(a).should be_empty
  end

  it "should consider '' to be different from null if the column allows null" do
    a = Sequel::Schema::DbColumn.new(:foo, :varchar, true, '', true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :varchar, true, nil, true, nil, nil)
    a.diff(b).should == [:default].to_set
    b.diff(a).should == [:default].to_set
  end

  it "should consider columns with different elements to be different" do
    a = Sequel::Schema::DbColumn.new(:foo, :enum, true, nil, true, nil, ["A"])
    b = Sequel::Schema::DbColumn.new(:foo, :enum, true, nil, true, nil, ["A", "B"])
    a.diff(b).should == [:elements].to_set
    b.diff(a).should == [:elements].to_set
  end

  it "should be buildable from a Hash" do
    Sequel::Schema::DbColumn.build_from_hash(:name => "foo", 
                                       :column_type => "integer").column_type.should == "integer"
    Sequel::Schema::DbColumn.build_from_hash('name' => "foo", 
                                       'column_type' => "integer").name.should == "foo"
  end
end
