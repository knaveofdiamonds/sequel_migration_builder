require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::Schema::DbColumn do

  before :each do
    @column = Sequel::Schema::DbColumn.new(:foo, :integer, false, 10, true, 10, nil)
  end

  it "should return a #define_statement" do
    expect(@column.define_statement).to eql("integer :foo, :null => false, :default => 10, :unsigned => true, :size => 10")
  end

  it "should return a primary_key invocation if single_primary_key is set and the column is an integer" do
    @column.single_primary_key = true
    expect(@column.define_statement).to eql("primary_key :foo, :type => :integer, :null => false, :default => 10, :unsigned => true, :size => 10")
  end

  it "should return a #drop_statement" do
    expect(@column.drop_statement).to eql("drop_column :foo")
  end

  it "should return an #add_statement" do
    expect(@column.add_statement).to eql("add_column :foo, :integer, :null => false, :default => 10, :unsigned => true, :size => 10")
  end

  it "should return a #change_null statement" do
    expect(@column.change_null_statement).to eql("set_column_allow_null :foo, false")
  end

  it "should return a #change_default statement" do
    expect(@column.change_default_statement).to eql("set_column_default :foo, 10")
  end

  it "should return a #change_type statement" do
    expect(@column.change_type_statement).to eql("set_column_type :foo, :integer, :default => 10, :unsigned => true, :size => 10")
  end

  it "should be diffable with another DbColumn" do
    other = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    expect(@column.diff(other)).to eql([:column_type].to_set)

    other = Sequel::Schema::DbColumn.new(:foo, :integer, true, 11, true, 10, nil)
    expect(@column.diff(other)).to eql([:null, :default].to_set)
  end

  it "should not consider allowing null being nil different from false" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, nil, 10, true, 10, nil)
    expect(a.diff(b)).to be_empty
    expect(b.diff(a)).to be_empty
  end

  it "should not consider size to be different if one of the sizes is nil" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 10, true, nil, nil)
    expect(a.diff(b)).to be_empty
    expect(b.diff(a)).to be_empty
  end

  it "should not consider 0 to be different from null if the column does not allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 0, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, nil, true, nil, nil)
    expect(a.diff(b)).to be_empty
    expect(b.diff(a)).to be_empty
  end

  it "should consider 0 to be different from null if the column does allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, true, 0, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, true, nil, true, nil, nil)
    expect(a.diff(b)).to eql([:default].to_set)
    expect(b.diff(a)).to eql([:default].to_set)
  end

  it "should consider 1 to be different from null" do
    a = Sequel::Schema::DbColumn.new(:foo, :smallint, false, 1, true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :smallint, false, nil, true, nil, nil)
    expect(a.diff(b)).to eql([:default].to_set)
    expect(b.diff(a)).to eql([:default].to_set)
  end

  it "should not consider '' to be different from null if the column does not allow nulls" do
    a = Sequel::Schema::DbColumn.new(:foo, :varchar, false, '', true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :varchar, false, nil, true, nil, nil)
    expect(a.diff(b)).to be_empty
    expect(b.diff(a)).to be_empty
  end

  it "should consider '' to be different from null if the column allows null" do
    a = Sequel::Schema::DbColumn.new(:foo, :varchar, true, '', true, 10, nil)
    b = Sequel::Schema::DbColumn.new(:foo, :varchar, true, nil, true, nil, nil)
    expect(a.diff(b)).to eql([:default].to_set)
    expect(b.diff(a)).to eql([:default].to_set)
  end

  it "should consider columns with different elements to be different" do
    a = Sequel::Schema::DbColumn.new(:foo, :enum, true, nil, true, nil, ["A"])
    b = Sequel::Schema::DbColumn.new(:foo, :enum, true, nil, true, nil, ["A", "B"])
    expect(a.diff(b)).to eql([:elements].to_set)
    expect(b.diff(a)).to eql([:elements].to_set)
  end

  it "should cast decimal defaults to the correct number" do
    a = Sequel::Schema::DbColumn.new(:foo, :decimal, true, '0.00', true, [4,2], nil)
    b = Sequel::Schema::DbColumn.new(:foo, :decimal, true, 0, true, [4,2], nil)

    expect(a.diff(b)).to eql(Set.new)
    expect(b.diff(a)).to eql(Set.new)
  end

  it "should output BigDecimal correctly in a  #define_statement" do
    expect(Sequel::Schema::DbColumn.new(:foo, :decimal, false, '1.1', true, [4,2], nil).define_statement).to eql("decimal :foo, :null => false, :default => BigDecimal.new('1.1'), :unsigned => true, :size => [4, 2]")
  end
  
  it "should be buildable from a Hash" do
    expect(Sequel::Schema::DbColumn.build_from_hash(:name => "foo", 
                                             :column_type => "integer").column_type).to eql("integer")
    expect(Sequel::Schema::DbColumn.build_from_hash('name' => "foo", 
                                             'column_type' => "integer").name).to eql("foo")
  end
end
