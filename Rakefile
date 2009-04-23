#!/usr/bin/env jruby

require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'spec/rake/spectask'
require 'hoe'
require 'lib/maxent_string_classifier'

CLEAN << 'pkg'

$LOAD_PATH << "lib"

gemspec = File.join( File.dirname(__FILE__), 'maxent_string_classifier.gemspec' )

Hoe.new("maxent_string_classifier", MaxentStringClassifier::VERSION ) do |p|
  p.description = %q{maxent_string_classifier is a JRuby library, which wraps the OpenNLP Maxent classifier and makes it easy to train and use string classifiers}
  p.email =  "craig@trampolinesystems.com"
  p.author =  "craig mcmillan"
  p.testlib = "spec"
end

task :cultivate => [:build_models] do
  system "touch Manifest.txt; jrake check_manifest | grep -v \"(in \" | patch"
  system "jrake debug_gem | grep -v \"(in \" > #{gemspec}"
end

# add a dependency to the :gem task
task :gem => [:build_models]

Spec::Rake::SpecTask.new do |t|
  t.name = :spec
  t.warning = true
  t.rcov = false
  t.spec_files = FileList["spec/**/*_spec.rb"]
  t.libs << "./lib"
end

desc "build and persist classifier models for all sub-directories of data directory"
task :build_models do
  require 'lib/maxent_string_classifier'
  Dir["data/*"].each do |dir|
    if File.directory?( dir )
      model = MaxentStringClassifier::Loader.train(File.basename(dir))
    end
  end
end

