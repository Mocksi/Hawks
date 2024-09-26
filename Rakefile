# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Build the Hawksi gem'
task :build do
  system 'gem build hawksi.gemspec'
end

desc 'Install the Hawksi gem locally'
task install: :build do
  system "gem install ./hawksi-#{Hawksi::VERSION}.gem"
end

desc 'Release the Hawksi gem to RubyGems'
task release: :build do
  system "gem push ./hawksi-#{Hawksi::VERSION}.gem"
end
