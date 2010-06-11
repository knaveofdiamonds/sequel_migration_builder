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
