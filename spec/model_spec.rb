#!/usr/bin/env jspec
raise "JRuby only" if RUBY_PLATFORM !~ /java/i

require 'rubygems'
require 'spec'
require 'yaml'
require 'fileutils'
$: << File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib" ))
require 'maxent_string_classifier'

module MaxentStringClassifier

  describe Model do
    def christmas_and_catfood_model
      g = ContextGenerator.new(:word_counts)
      File.should_receive(:read).with("/bar/foo.txt").and_return("first day christmas\n\nate sausages")
      File.should_receive(:read).with("/bar/kittens.txt").and_return( "tomorrow catfood\n\ntonight mice")
      Model.train_from_files(g, ["/bar/foo.txt", "/bar/kittens.txt" ])
    end

    def test_christmas_and_catfood_model( model )
      # classes are completely independent, so these results are obious
      model.classify("christmas")[0][0].should ==("foo")
      model.classify("mice")[0][0].should ==("kittens")
    end

    describe "train_from_files" do
      it "should train a model from a list of files" do
        model = christmas_and_catfood_model
        test_christmas_and_catfood_model( model )
      end
    end

    describe "write" do
      it "should write a trained model to a file" do
        begin
          model = christmas_and_catfood_model
          
          fname = "christmas_catfood.txt.gz"
          File.delete(fname) if File.exists?(fname)
          
          # maxent_model opens the file itself, in java layer, so can't stub it
          model.write(fname)
          File.exists?(fname).should ==(true)
          File.size(fname).should >(0)
        ensure
          File.delete(fname) if File.exists?(fname)
        end
      end
    end

    describe "load" do
      it "should load a model from a file" do
        begin
          model = christmas_and_catfood_model
          fname = "christmas_catfood.txt.gz"
          File.delete(fname) if File.exists?(fname)
          model.write(fname)

          loaded_model = Model.load( model.context_generator, fname )
          test_christmas_and_catfood_model( loaded_model )
        ensure
          File.delete(fname) if File.exists?(fname)
        end
      end
    end

    describe "classify" do
      it "should classify a string using a trained model" do
        model = christmas_and_catfood_model
        test_christmas_and_catfood_model( model )
      end
    end
  end
end
