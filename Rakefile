require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sequel_migration_builder"
    gem.summary = "Build Sequel Migrations based on the differences between two schemas"
    gem.description = "Build Sequel Migrations based on the differences between two schemas"
    gem.email = "roland.swingler@gmail.com"
    gem.homepage = "http://github.com/knaveofdiamonds/sequel_migration_builder"
    gem.authors = ["Roland Swingler"]
    gem.add_dependency "sequel", ">= 3.20.0"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rcov = true
  spec.rcov_opts = "-x spec/ -x /home"
end

task :spec => :check_dependencies

task :default => :spec

desc "Flog this baby!"
task :flog do
  sh 'find lib -name "*.rb" | xargs flog'
end
