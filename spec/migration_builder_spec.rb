require File.dirname(__FILE__) + "/spec_helper"

describe Sequel::MigrationBuilder do
  
  it "should return nil if the table hash is empty" do
    Sequel::MigrationBuilder.new(stub(:db)).generate_migration({}).should be_nil
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
#    mock_db.should_receive(:table_exists?).at_least(:once).and_return(false)
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
#    mock_db.should_receive(:table_exists?).at_least(:once).and_return(false)
    Sequel::MigrationBuilder.new(mock_db).generate_migration(tables).should == expected
  end
end
