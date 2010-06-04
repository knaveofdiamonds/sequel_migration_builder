require File.dirname(__FILE__) + "/spec_helper"

describe "Sequel::Schema::MigrationOperations.build" do

  it "should return an empty Array if there are no differences between column definitions" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :integer}, 
                                                    {:name => :foo, :type => :integer})
    ops.should == []
  end

  it "should return a ChangeColumnType operation if the types are different" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :integer}, 
                                                    {:name => :foo, :type => :smallint})

    ops.first.should be_kind_of(Sequel::Schema::MigrationOperations::ChangeColumn)
  end

  it "should return a ChangeColumnType operation if the sizes are different" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :char, :size => 20}, 
                                                    {:name => :foo, :type => :char, :size => 10})

    ops.first.should be_kind_of(Sequel::Schema::MigrationOperations::ChangeColumn)
  end

  it "should return a ChangeColumnType operation if the unsigned value is different" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :integer, :unsigned => true}, 
                                                    {:name => :foo, :type => :integer, :unsigned => false})

    ops.first.should be_kind_of(Sequel::Schema::MigrationOperations::ChangeColumn)
  end

  it "should return a ChangeColumnNull operation if the unsigned value is different" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :integer, :null => true}, 
                                                    {:name => :foo, :type => :integer, :null => false})

    ops.first.should be_kind_of(Sequel::Schema::MigrationOperations::ChangeColumn)
  end

  it "should return a ChangeColumnDefault operation if the unsigned value is different" do
    pending
    ops = Sequel::Schema::MigrationOperations.build({:name => :foo, :type => :integer, :default => 1}, 
                                                    {:name => :foo, :type => :integer, :default => 2})

    ops.first.should be_kind_of(Sequel::Schema::MigrationOperations::ChangeColumn)
  end

end
