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
  up do
    create_table :example_table do
      integer :foo, :null => false
    end
  end

  down do
    drop_table :example_table
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
  up do
    create_table :example_table do
      integer :foo, :null => false
      varchar :bar, :null => false
    end

    create_table :example_table_2 do
      integer :foo
    end
  end

  down do
    drop_table :example_table_2
    drop_table :example_table
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
  integer :foo, :null => false
  varchar :bar, :null => false

  primary_key :foo
end
END

    Sequel::MigrationBuilder.new(mock_db).create_table_statement(:example_table, table).join("\n").
      should == expected.strip
  end


  context "when a table needs to be altered" do
    before :each do
      @tables = { :example_table =>
        {:columns => [{:name => :foo, :column_type => :integer}, {:name => :bar, :column_type => :varchar}]}
      }
      @mock_db = mock(:database)
      @mock_db.should_receive(:tables).at_least(:once).and_return([:example_table])
      @mock_db.should_receive(:schema).with(:example_table).and_return([[:foo, {:type => :integer, :db_type => "smallint(5) unsigned", :allow_null => true, :ruby_default => 10}]])

    end

    it "should return an alter table statement with column changes for #generate_up" do
      expected = <<-END
up do
  alter_table :example_table do
    set_column_type :foo, :integer, :default => nil
    set_column_allow_null :foo, false
    add_column :bar, :varchar, :null => false
  end
end
END
      Sequel::MigrationBuilder.new(@mock_db).generate_up(@tables).join("\n").should == expected
    end

    it "should return an alter table statement with column changes for #generate_down" do
      expected = <<-END
down do
  alter_table :example_table do
    set_column_type :foo, :smallint, :default => 10, :unsigned => true
    set_column_allow_null :foo, true
    drop_column :bar
  end
end
END
      Sequel::MigrationBuilder.new(@mock_db).generate_down(@tables).join("\n").should == expected.strip
    end
  end

  it "should drop the table if the table exists in the database but not the table hash" do
    pending # Deal with in a later version.
    mock_db = mock(:database)
    mock_db.should_receive(:tables).at_least(:once).and_return([:example_table])
    
    expected = <<-END
up do
  drop_table :example_table
end
END
    Sequel::MigrationBuilder.new(mock_db).generate_up({}).join("\n").should == expected
  end
end
