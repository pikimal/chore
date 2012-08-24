#!/usr/bin/env ruby

require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

task :default => :test

RSpec::Core::RakeTask.new(:test) do |spec|
  spec.rspec_opts = []
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = false
end
