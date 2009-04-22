#!/usr/bin/env jruby

require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'spec/rake/spectask'

CLEAN << 'pkg'
CLEAN.insert( -1, *FileList["data/**/*.txt.gz"] )

$LOAD_PATH << "lib"

gemspec = eval( File.read( File.join( File.dirname(__FILE__), 'maxent_string_classifier.gemspec' ) ) )

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
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

