require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::Schema::DbIndex do
  it "should have a name" do
    expect(Sequel::Schema::DbIndex.new('foo_index', :foo).name).to eql(:foo_index)
  end

  it "can have columns" do
    expect(Sequel::Schema::DbIndex.new('foo_index', [:foo, :bar]).columns).to eql([:foo, :bar])
  end

  it "converts a single column symbol to a 1 element array of columns" do
    expect(Sequel::Schema::DbIndex.new('foo_index', :foo).columns).to eql([:foo])
  end

  it "is not unique by default" do
    expect(Sequel::Schema::DbIndex.new('foo_index', :foo)).not_to be_unique
  end

  it "can be unique" do
    expect(Sequel::Schema::DbIndex.new('foo_index', :foo, true)).to be_unique
  end

  it "should respond to multi_column?" do
    expect(Sequel::Schema::DbIndex.new('foo_index', :foo, true)).not_to be_multi_column
    expect(Sequel::Schema::DbIndex.new('foo_index', [:foo, :bar], true)).to be_multi_column
  end

  it "should be equal when compared with ==" do
    i1 = Sequel::Schema::DbIndex.new('foo_idx', :foo, true)

    expect(i1).to eql(Sequel::Schema::DbIndex.new('foo_idx', :foo, true))
    expect(i1).to eql(Sequel::Schema::DbIndex.new('foo_idx', [:foo], true))
    expect(i1).to_not eql(Sequel::Schema::DbIndex.new('foo_idx', :foo, false))
    expect(i1).to_not eql(Sequel::Schema::DbIndex.new('foo', :foo, true))
    expect(i1).to_not eql(Sequel::Schema::DbIndex.new('foo_idx', :bar, true))
  end

  it "should be equal when compared with eql?" do
    i1 = Sequel::Schema::DbIndex.new('foo_idx', :foo, true)

    expect(i1.hash).to eql(Sequel::Schema::DbIndex.new('foo_idx', :foo, true).hash)
    expect(i1).to be_eql(Sequel::Schema::DbIndex.new('foo_idx', :foo, true))
  end

  it "should ensure nil as unique is converted to false" do
    expect(([Sequel::Schema::DbIndex.new(:foo_idx, :foo, :unique => nil)] - [Sequel::Schema::DbIndex.new(:foo_idx, :foo, :unique => false)])).to eql([])
  end
  
  it "can be built from a hash returned by Sequel::Database#indexes" do
    hsh = {:foo_idx => {:columns => [:foo], :unique => true}}
    expect(Sequel::Schema::DbIndex.build_from_hash(hsh)).
      to eql([Sequel::Schema::DbIndex.new(:foo_idx, :foo, true)])
  end

  it "should have a define statement" do
    expect(Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).define_statement).to eql("index :foo, :name => :foo_idx, :unique => true")
  end

  it "should have a define statement for multiple columns" do
    expect(Sequel::Schema::DbIndex.new(:foo_idx, [:foo, :bar], true).define_statement).to eql("index [:foo, :bar], :name => :foo_idx, :unique => true")
  end

  it "should not output the unique value if it is false" do
    expect(Sequel::Schema::DbIndex.new(:foo_idx, :foo).define_statement).to eql("index :foo, :name => :foo_idx")
  end

  it "should have an add_index statement" do
    expect(Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).add_statement).to eql("add_index :foo, :name => :foo_idx, :unique => true")
  end

  it "should have an drop_index statement" do
    expect(Sequel::Schema::DbIndex.new(:foo_idx, :foo, true).drop_statement).to eql("drop_index :foo, :name => :foo_idx")
  end
end
