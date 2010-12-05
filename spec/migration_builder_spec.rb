require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::MigrationBuilder do
  
  it "should return nil if the table hash is empty and the database has no tables" do
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    Sequel::MigrationBuilder.new(mock_db).generate_migration({}).should be_nil
  end

  it "should produce a simple migration string given a database connection and a hash of tables" do
    tables = {}
    tables[:example_table] = {
      :columns => [{:name => :foo, :column_type => :integer}]
    }

    expected = <<-END
Sequel.migration do
  change do
    create_table :example_table do
      integer :foo, :null => false
    end
  end
end
END
    
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    Sequel::MigrationBuilder.new(mock_db).generate_migration(tables).should == expected
  end

  it "should produce statements for multiple new tables" do
    tables = {}
    tables[:example_table] = {
      :columns => [{:name => :foo, :column_type => :integer}, {:name => :bar, :column_type => :varchar}]
    }

    tables[:example_table_2] = {
      :columns => [{:name => :foo, :column_type => :integer, :null => true}]
    }

    expected = <<-END
Sequel.migration do
  change do
    create_table :example_table do
      integer :foo, :null => false
      varchar :bar, :null => false
    end

    create_table :example_table_2 do
      integer :foo
    end
  end
end
END
    
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    Sequel::MigrationBuilder.new(mock_db).generate_migration(tables).should == expected
  end

  it "should add the primary key of the table" do
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    table = {
      :primary_key => :foo,
      :columns => [{:name => :foo, :column_type => :integer}, {:name => :bar, :column_type => :varchar}]
    }

    expected = <<-END
create_table :example_table do
  primary_key :foo, :type => :integer, :null => false
  varchar :bar, :null => false
end
END

    Sequel::MigrationBuilder.new(mock_db).create_table_statement(:example_table, table).join("\n").
      should == expected.strip
  end

  it "should add the table options do the create_table statement" do
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    table = {
      :table_options => {:engine => "myisam"},
      :columns => [{:name => :foo, :column_type => :integer}]
    }

    expected = <<-END
create_table :example_table, :engine => "myisam" do
  integer :foo, :null => false
end
END

    Sequel::MigrationBuilder.new(mock_db).create_table_statement(:example_table, table).join("\n").
      should == expected.strip
  end

  it "should add indexes to the create_table statement" do
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([])
    table = {
      :indexes => {:foo_index => {:columns => :foo, :unique => true}},
      :columns => [{:name => :foo, :column_type => :integer}]
    }

    expected = <<-END
create_table :example_table do
  integer :foo, :null => false

  index :foo, :name => :foo_index, :unique => true
end
END

    Sequel::MigrationBuilder.new(mock_db).create_table_statement(:example_table, table).join("\n").
      should == expected.strip
  end
  
  context "when a table needs to be altered" do
    before :each do
      @tables = { :example_table =>
        { :indexes => {:foo_index => {:columns => :foo, :unique => true}},
          :columns => [{:name => :foo, :column_type => :integer}, {:name => :bar, :column_type => :varchar}]}
      }
      @mock_db = mock(:database)
      @mock_db.should_receive(:tables).at_least(:once).and_return([:example_table])
      @mock_db.should_receive(:indexes).with(:example_table).and_return({})
      @mock_db.should_receive(:schema).with(:example_table).and_return([[:foo, {:type => :integer, :db_type => "smallint(5) unsigned", :allow_null => true, :ruby_default => 10}]])

    end

    it "should return an alter table statement with column changes for #generate_up" do
      expected = <<-END
change do
  alter_table :example_table do
    set_column_type :foo, :integer, :default => nil
    set_column_allow_null :foo, false
    add_column :bar, :varchar, :null => false
    add_index :foo, :name => :foo_index, :unique => true
  end
end
END
      Sequel::MigrationBuilder.new(@mock_db).
        generate_migration_body(@tables).join("\n").should == expected.strip
    end
  end

  it "should drop the table if the table exists in the database but not the table hash" do
    pending # Deal with in a later version.
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([:example_table])
    
    expected = <<-END
change do
  drop_table :example_table
end
END
    Sequel::MigrationBuilder.new(mock_db).generate_up({}).join("\n").should == expected
  end
end
