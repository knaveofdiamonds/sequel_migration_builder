require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::Schema::DbIndex do
  it "should have a name" do
    Sequel::Schema::DbIndex.new('foo_index', :foo).name.should == :foo_index
  end

  it "can have columns" do
    Sequel::Schema::DbIndex.new('foo_index', [:foo, :bar]).columns.should == [:foo, :bar]
  end

  it "converts a single column symbol to a 1 element array of columns" do
    Sequel::Schema::DbIndex.new('foo_index', :foo).columns.should == [:foo]
  end

  it "is not unique by default" do
    Sequel::Schema::DbIndex.new('foo_index', :foo).should_not be_unique
  end

  it "can be unique" do
    Sequel::Schema::DbIndex.new('foo_index', :foo, true).should be_unique
  end

  it "should respond to multi_column?" do
    Sequel::Schema::DbIndex.new('foo_index', :foo, true).should_not be_multi_column
    Sequel::Schema::DbIndex.new('foo_index', [:foo, :bar], true).should be_multi_column
  end

  it "should be equal when compared with ==" do
    i1 = Sequel::Schema::DbIndex.new('foo_idx', :foo, true)

    i1.should == Sequel::Schema::DbIndex.new('foo_idx', :foo, true)
    i1.should == Sequel::Schema::DbIndex.new('foo_idx', [:foo], true)
    i1.should_not == Sequel::Schema::DbIndex.new('foo_idx', :foo, false)
    i1.should_not == Sequel::Schema::DbIndex.new('foo', :foo, true)
    i1.should_not == Sequel::Schema::DbIndex.new('foo_idx', :bar, true)
  end

  it "should be equal when compared with eql?" do
    i1 = Sequel::Schema::DbIndex.new('foo_idx', :foo, true)

    i1.hash.should == Sequel::Schema::DbIndex.new('foo_idx', :foo, true).hash
    i1.should be_eql(Sequel::Schema::DbIndex.new('foo_idx', :foo, true))
  end

  it "should be the same when indexes have the same name" do
    i1 = Sequel::Schema::DbIndex.new('foo_idx', :foo, true)

    i1.should be_same(Sequel::Schema::DbIndex.new('foo_idx', :foo, false))
    i1.should be_same(Sequel::Schema::DbIndex.new('foo_idx', [:foo, :bar], true))
    i1.should_not be_same(Sequel::Schema::DbIndex.new('foo_bar_idx', :foo, true))
  end
  
  it "can be built from a hash returned by Sequel::Database#indexes" do
    hsh = {:foo_idx => {:columns => [:foo], :unique => true}}
    Sequel::Schema::DbIndex.build_from_hash(hsh).should ==
      [Sequel::Schema::DbIndex.new(:foo_idx, :foo, true)]
  end

  it "should have a define statement" do
    Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).define_statement.should ==
      "index :foo, :name => :foo_idx, :unique => true"
  end

  it "should have a define statement for multiple columns" do
    Sequel::Schema::DbIndex.new(:foo_idx, [:foo, :bar], true).define_statement.should ==
      "index [:foo, :bar], :name => :foo_idx, :unique => true"
  end

  it "should not output the unique value if it is false" do
    Sequel::Schema::DbIndex.new(:foo_idx, :foo).define_statement.should ==
      "index :foo, :name => :foo_idx"
  end

  it "should have an add_index statement" do
    Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).add_statement.should ==
      "add_index :foo, :name => :foo_idx, :unique => true"
  end

  it "should have an drop_index statement" do
    Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).drop_statement.should ==
      "drop_index :foo, :name => :foo_idx"
  end
end
