require File.dirname(__FILE__) + "/spec_helper"

def build_column(hash)
  Sequel::Schema::DbColumn.build_from_hash(hash)
end

describe "Sequel::Schema::AlterTableOperations.build_column_operations" do
  it "should return an empty Array if there are no differences between column definitions" do
    a = build_column(:name => :foo, :column_type => :integer)
    b = build_column(:name => :foo, :column_type => :integer)

    Sequel::Schema::AlterTableOperations.build_column_operations(a,b).should == []
  end

  it "should return a ChangeColumn operation if the types are different" do
    a = build_column(:name => :foo, :column_type => :integer)
    b = build_column(:name => :foo, :column_type => :smallint)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_type :foo, :smallint, :default => nil"
  end

  it "should return a ChangeColumn operation if the sizes are different" do
    a = build_column(:name => :foo, :column_type => :char, :size => 20)
    b = build_column(:name => :foo, :column_type => :char, :size => 10)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_type :foo, :char, :default => nil, :size => 10"
  end

  it "should return a ChangeColumn operation if the unsigned value is different" do
    a = build_column(:name => :foo, :column_type => :integer, :unsigned => true)
    b = build_column(:name => :foo, :column_type => :integer, :unsigned => false)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_type :foo, :integer, :default => nil, :unsigned => false"
  end

  it "should return a ChangeColumn operation to set the null value if the null value is different" do
    a = build_column(:name => :foo, :column_type => :integer, :null => true)
    b = build_column(:name => :foo, :column_type => :integer, :null => false)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_allow_null :foo, false"
  end

  it "should return a ChangeColumn operation to set the default if the default value is different" do
    a = build_column(:name => :foo, :column_type => :integer, :default => 1)
    b = build_column(:name => :foo, :column_type => :integer, :default => 2)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_default :foo, 2"
  end

  it "should only return 1 operation if the default and other values are different" do
    a = build_column(:name => :foo, :column_type => :integer, :default => 1)
    b = build_column(:name => :foo, :column_type => :smallint, :default => 2)
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.size.should == 1
    ops.first.up.should == "set_column_type :foo, :smallint, :default => 2"
  end
end

describe "Sequel::Schema::AlterTableOperations.build" do
  it "should return an empty array if nothing is different" do
    table_a = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    table_b = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    ops = Sequel::Schema::AlterTableOperations.build(table_a,table_b)

    ops.should == []
  end

  it "should return an add column operation if the column is new" do
    table_a = {:name => :example_table,
      :columns => []}
    table_b = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    ops = Sequel::Schema::AlterTableOperations.build(table_a,table_b)

    ops.size.should == 1
    ops.first.should be_kind_of(Sequel::Schema::AlterTableOperations::AddColumn)
  end

  it "should return a drop column operation if the column has been removed" do
    table_a = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    table_b = {:name => :example_table,
      :columns => []}
    ops = Sequel::Schema::AlterTableOperations.build(table_a,table_b)

    ops.size.should == 1
    ops.first.should be_kind_of(Sequel::Schema::AlterTableOperations::DropColumn)
  end

  it "should return a change column operation if columns are different" do
    table_a = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    table_b = {:name => :example_table,
      :columns => [build_column(:name => :foo, :column_type => :smallint)]}
    ops = Sequel::Schema::AlterTableOperations.build(table_a,table_b)

    ops.size.should == 1
    ops.first.should be_kind_of(Sequel::Schema::AlterTableOperations::ChangeColumn)
  end
end
