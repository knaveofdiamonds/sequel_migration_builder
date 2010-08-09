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

  it "should return a ChangeColumn operation if the elements are different" do
    a = build_column(:name => :foo, :column_type => :enum, :elements => ["A"])
    b = build_column(:name => :foo, :column_type => :enum, :elements => ["A", "B"])
    ops = Sequel::Schema::AlterTableOperations.build_column_operations(a,b)

    ops.first.up.should == "set_column_type :foo, :enum, :default => nil, :elements => [\"A\", \"B\"]"
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

  it "should not output a drop index if the index's column is also removed" do
    table_a = {:name => :example_table,
      :indexes => {:foo_idx => {:columns => [:foo]}},
      :columns => [build_column(:name => :foo, :column_type => :integer)]}
    table_b = {:name => :example_table, :indexes => {}, :columns => []}
    ops = Sequel::Schema::AlterTableOperations.build(table_a,table_b)

    ops.size.should == 1
    ops.first.should be_kind_of(Sequel::Schema::AlterTableOperations::DropColumn)
  end
end

describe Sequel::Schema::AlterTableOperations::AddColumn do
  before(:each) { @mock_column = mock() }

  it "should ask the column for its add column statement on #up" do
    @mock_column.should_receive(:add_statement).and_return("add")
    @mock_column.should_receive(:drop_statement)
    Sequel::Schema::AlterTableOperations::AddColumn.new(@mock_column).up.should == "add"
  end

  it "should ask the column for its drop column statement on #down" do
    @mock_column.should_receive(:add_statement)
    @mock_column.should_receive(:drop_statement).and_return("drop")
    Sequel::Schema::AlterTableOperations::AddColumn.new(@mock_column).down.should == "drop"
  end
end

describe Sequel::Schema::AlterTableOperations::DropColumn do
  before(:each) { @mock_column = mock() }

  it "should ask the column for its drop column statement on #up" do
    @mock_column.should_receive(:add_statement)
    @mock_column.should_receive(:drop_statement).and_return("drop")
    Sequel::Schema::AlterTableOperations::DropColumn.new(@mock_column).up.should == "drop"
  end

  it "should ask the column for its add column statement on #down" do
    @mock_column.should_receive(:drop_statement)
    @mock_column.should_receive(:add_statement).and_return("add")
    Sequel::Schema::AlterTableOperations::DropColumn.new(@mock_column).down.should == "add"
  end
end

describe Sequel::Schema::AlterTableOperations::ChangeColumn do
  it "should ask the new column for statement on #up" do
    new = mock(:new)
    old = mock(:old)
    old.should_receive(:change_type_statement)
    new.should_receive(:change_type_statement).and_return("new")
    Sequel::Schema::AlterTableOperations::ChangeColumn.new(old, new, :change_type_statement).up.should == "new"
  end

  it "should ask the old column for statement on #down" do
    new = mock(:new)
    old = mock(:old)
    old.should_receive(:change_type_statement).and_return("old")
    new.should_receive(:change_type_statement)
    Sequel::Schema::AlterTableOperations::ChangeColumn.new(old, new, :change_type_statement).down
  end
end


describe Sequel::Schema::AlterTableOperations::AddIndex do
  it "should add the index on #up" do
    Sequel::Schema::AlterTableOperations::AddIndex.new(:foo_index, :foo, true).up.
      should == "add_index :foo, :name => :foo_index, :unique => true"
  end

  it "should drop the index on #down" do
    Sequel::Schema::AlterTableOperations::AddIndex.new(:foo_index, :foo, true).down.
      should == "drop_index :foo, :name => :foo_index"
  end
end

describe Sequel::Schema::AlterTableOperations::DropIndex do
  it "should add the index on #down" do
    Sequel::Schema::AlterTableOperations::DropIndex.new(:foo_index, :foo, true).down.
      should == "add_index :foo, :name => :foo_index, :unique => true"
  end

  it "should drop the index on #up" do
    Sequel::Schema::AlterTableOperations::DropIndex.new(:foo_index, :foo, true).up.
      should == "drop_index :foo, :name => :foo_index"
  end
end
