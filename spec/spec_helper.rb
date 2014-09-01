require 'rubygems'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sequel'
require 'sequel/migration_builder'
require 'rspec'


RSpec.configure do |config| 
end
