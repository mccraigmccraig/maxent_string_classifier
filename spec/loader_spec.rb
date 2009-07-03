#!/usr/bin/env jspec
raise "JRuby only" if RUBY_PLATFORM !~ /java/i

require 'rubygems'
require 'spec'
require 'yaml'
require 'fileutils'
$: << File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib" ))
require 'maxent_string_classifier'

module MaxentStringClassifier

  describe Loader do
    def prepare_model_dir(dir, opts={})
      FileUtils.mkdir_p( dir )
      File.open( File.join(dir, "model.yml"), "w" ) { |f| f << opts.to_yaml }
      File.open( File.join(dir,"christmas.txt") , "w") { |f| f << "first day christmas\n\nate sausages" }
      File.open( File.join(dir,"kittens.txt"), "w" ) { |f| f << "tomorrow catfood\n\ntonight mice" }
    end

    def test_christmas_and_catfood_model( model )
      # classes are completely independent, so these results are obious
      model.classify("christmas")[0][0].should ==("christmas")
      model.classify("mice")[0][0].should ==("kittens")
    end

    describe "create_context_generator" do
      it "should create a ContextGenerator from a model options hash" do
        g = Loader.create_context_generator({ :featuresets=>[:c_token, :c_url]})
        g.featuresets.should ==([:c_token, :c_url])
      end

      it "should create a ContextGenerator with :word_counts featuresets if non given" do
        g = Loader.create_context_generator({})
        g.featuresets.should ==([:word_counts])
      end
    end

    describe "train" do
      it "should train a model from an absoute directory of files" do
        File.should_receive(:directory?).with("/foo").and_return(true)
        Dir.should_receive(:[]).with("/foo/*.txt").and_return(["/foo/christmas.txt", "/foo/kittens.txt"])
        File.should_receive(:read).with("/foo/christmas.txt").and_return("first day christmas\n\nate sausages")
        File.should_receive(:read).with("/foo/kittens.txt").and_return("tomorrow catfood\n\ntonight mice")
        File.should_receive(:file?).with("/foo/model.yml").and_return(true)
        File.should_receive(:read).with("/foo/model.yml").and_return({:featuresets=>[:word_counts]}.to_yaml)

        model = Loader.train("/foo", false)
        
        test_christmas_and_catfood_model( model )
      end

      it "should train a model from a relative directory of files" do
        File.should_receive(:directory?).with("foo").and_return(false)

        # fork meet eye
        idir = nil
        File.should_receive(:directory?).and_return do |d| 
          idir = d if d =~ /.+\/foo/
        end
        Dir.should_receive(:[]).and_return{ |d| d.should ==(File.join(idir,"*.txt")) ;  [File.join(idir,"christmas.txt"), File.join(idir,"kittens.txt")] }
        File.should_receive(:file?).and_return{|f| f.should==(File.join(idir,"model.yml")); true}
        File.should_receive(:read).exactly(3).times.and_return do|f| 
          h = { 
            File.join(idir,"christmas.txt") => "first day christmas\n\nate sausages",
            File.join(idir,"kittens.txt") => "tomorrow catfood\n\ntonight mice",
            File.join(idir,"model.yml") => {:featuresetes=>[:word_counts]}.to_yaml
          }
          
          h[f]
        end

        model = Loader.train("foo", false )
        
        test_christmas_and_catfood_model( model )
      end

      it "should persist the trained model to the parent directory of the model directory" do
        begin
          prepare_model_dir("./foo/bar")
          model = Loader.train( "./foo/bar" )
          
          File.exists?( "./foo/bar/bar.txt.gz" ).should ==(true)
        ensure
          FileUtils.rm_rf( "./foo" )
        end
      end

      it "should read featuresets from a featuresets.yml file in the model directory" do
        begin
          prepare_model_dir("./foo/bar", { :featuresets=>[:c_url,:c_email]})
        
          model = Loader.train( "./foo/bar" , false)
          model.context_generator.featuresets.should ==([:c_url, :c_email])
        ensure
          FileUtils.rm_rf( "./foo" )
        end
      end

      it "should read featuresets from a featuresets.yml file in the parent of the model directory" do
        begin
          prepare_model_dir("./foo/bar",  { :featuresets=>[:c_url,:c_email]} )
        
          model = Loader.train( "./foo/bar" , false)
          model.context_generator.featuresets.should ==([:c_url, :c_email])
        ensure
          FileUtils.rm_rf( "./foo" )
        end
      end
    end

    describe "load" do
      it "should load a persisted model from the parent directory of the given directory" do
        begin
          prepare_model_dir("./foo/bar")
          model = Loader.train( "./foo/bar" )
          
          File.exists?( "./foo/bar/bar.txt.gz" ).should ==(true)

          read_model = Loader.load( "./foo/bar" )
          test_christmas_and_catfood_model( read_model )
        ensure
          FileUtils.rm_rf( "./foo" )
        end
      end
    end

    describe "test_against" do
      it "should test a model against the classifications in the given directory" do
        begin
          prepare_model_dir("./foo/bar")
          model = Loader.train( "./foo/bar" )
          FileUtils.mkdir_p("./foo/test")
          File.open("./foo/test/christmas.txt", "w") { |f| f << "christmas\n\nsausages"}
          File.open("./foo/test/kittens.txt", "w") { |f| f << "catfood\n\nmice"}
          
          File.exists?( "./foo/bar/bar.txt.gz" ).should ==(true)

          tr = Loader.test_against(model, "./foo/test")
          tr.should ==({ "christmas"=>[2,0], "kittens"=>[2,0]})
        ensure
          FileUtils.rm_rf( "./foo" )
        end
      end
    end

  end
end
