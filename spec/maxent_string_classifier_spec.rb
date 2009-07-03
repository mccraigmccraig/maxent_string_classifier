#!/usr/bin/env jspec
raise "JRuby only" if RUBY_PLATFORM !~ /java/i

require 'rubygems'
require 'spec'
require 'yaml'
require 'fileutils'
require File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib", "maxent_string_classifier" ) )

module MaxentStringClassifier

  describe ContextGenerator do
    
    def test_cg(featuresets, test_str, result)
      g = ContextGenerator.new(featuresets)
      ctx = g.generate(test_str)
      ctx.should ==(result)
    end

    it "should have a word_counts featureset which counts words" do
      test_cg(:word_counts, "some word word repeated", { "1w:some"=>1, "1w:word"=>2, "1w:repeated"=>1})
    end

    it "should have a char_counts featureset which counts characters" do
      test_cg(:char_counts, "some chars chars", { "1c:s"=>3, "1c:o"=>1, "1c:m"=>1, "1c:e"=>1, "1c:c"=>2, "1c:h"=>2, "1c:a"=>2, "1c:r"=>2 } )
    end

    it "should have a char_bigram_counts featureset which counts character bigrams" do
      test_cg(:char_bigram_counts, "one mon", 
              { "2c:on"=>2, "2c:ne"=>1, "2c:mo"=>1 })
    end

    it "should have a char_trigram_counts featureset which counts character trigrams" do
      test_cg(:char_trigram_counts, "bank ewbanks",
              { "3c:ban"=>2, "3c:ank"=>2, "3c:ewb"=>1, "3c:wba"=>1, "3c:nks"=>1 })
    end

    it "should have a bigram_counts_context featureset which counts bigrams" do
      test_cg(:bigram_counts, "one two three one two",
              { "2w:one_two"=>2, 
                "2w:two_three"=>1,
                "2w:three_one"=>1})
    end
    
    it "should have a trigram_counts_context featureset which counts trigrams" do
      test_cg(:trigram_counts, "one two three one two three four",
              { "3w:one_two_three"=>2,
                "3w:two_three_one"=>1,
                "3w:three_one_two"=>1,
                "3w:two_three_four"=>1
              })
    end

    it "should have a c_tokens featureset which counts tokens" do
      g = ContextGenerator.new(:c_token)
      str = "I'm working through interface bugs and tidying. There's loads of it."
      toks = g.cleanup( str ).split
      ctx = g.generate( str )
      ctx["c_token"].should ==(toks.length)
    end

    it "should have a c_words featureset which counts words" do
      test_cg(:c_word, 
              "one 1 two ! three four five and six but not % or 23 or 01-756",
              { "c_word"=> 11 } )
    end

    it "should have a c_cap_words featureset which counts capitalised words" do
      test_cg(:c_cap_word,
              "One 1 Two and Three but not four five and six or % or 23 or 01-756",
              { "c_cap_word"=>3 })
    end

    it "should have a c_natnums featureset which counts natural numbers" do
      test_cg(:c_natnum,
              "One 1 Two and Three but not four five and six or % or 23 or 01-756 23.5",
              { "c_natnum"=>2 })
    end

    it "should have a c_telno featureset which counts telephone numbers" do
      test_cg(:c_telno,
              "One 1 Two and Three but not (01273) 123-456 ... 020 7253 6959 four five and six or % or 23 or 01-756 23.5",
              { "c_telno"=> 3 })
    end

    it "should have a c_url featureset which counts urls" do
      test_cg(:c_url,
              "One 1 Two and Three but www.trampolinesystems.com ... http://www.ms.com, and perhaps ftp://abc.com or mailto:foo@bar.com huh",
              { "c_url"=> 4 })
    end

    it "should have a c_email featureset which counts email addresses" do
      test_cg(:c_email,
              "One 1 Two and Three but foo@bar.com ... abc@def.com, http://www.foo.com kitten@cats.com or mailto:foo@bar.com huh",
              { "c_email"=>4 })
    end

    it "should be able to use a custom cleanup block" do
      g = ContextGenerator.new(:c_token, Proc.new{ |str| str.gsub(/%%/, ' ') } )
      str = "one%%two%%three and four"
      ctx = g.generate(str)
      ctx["c_token"].should ==(5)
    end

    describe "cleanup" do
      it "should split punctuation away from words" do
        g = ContextGenerator.new(:c_token)
        g.cleanup("+words\" with, ?punctuation! . attached# %@front (and& back*").gsub(/ +/, ' ').should ==(
          "+ words \" with , ? punctuation ! . attached # %@ front ( and & back *" )                                                                                                        
      end
    end

    it "should be able to generate a context from multiple featuresets" do
      test_cg([:c_url, :c_email],
              "One 1 Two and Three but foo@bar.com ... abc@def.com, http://www.foo.com kitten@cats.com or mailto:foo@bar.com huh",
              { "c_email"=>4, "c_url"=>2 })
    end

    it "should be able to define a feature using regex scan" do
      class Foo
        class << self
          include ContextGenerator::FeatureGenerators
        end

        def_regex_feature( :c_foo, /123/ )
      end

      ctx = Foo.new.c_foo_context( "abc 123 def")
      ctx["c_foo"].should ==(1)
    end

    it "should be able to define a feature using split and a regex select" do
      class Bar
        class << self
          include ContextGenerator::FeatureGenerators
        end

        def_split_select_feature( :c_bar, /\d+/ )
      end

      ctx = Bar.new.c_bar_context( "abc 123 def 456 ")
      ctx["c_bar"].should ==(2)
    end

    it "should be able to define a feature using a custom split pattern and a regex select" do
      class FooBar
        class << self
          include ContextGenerator::FeatureGenerators
        end

        def_split_select_feature( :c_foo_bar, /\d+/ , /%/)
      end

      ctx = FooBar.new.c_foo_bar_context( "123%456%789")
      ctx["c_foo_bar"].should ==(3)
    end
  end

  describe FilesetEventStream do

    def create_event_stream()
      g = ContextGenerator.new(:word_counts)

      File.should_receive(:read).with("/foo/bar").and_return( "once upon a time\n\ni ate a sack of mice")
      File.should_receive(:read).with("/pets/kittens" ).and_return( "kittens are quite nice\n\nfor furry psychopathic killers" )
      
      FilesetEventStream.new(g, ["/foo/bar", "/pets/kittens"] )
    end

    it "should generate one event per string of a set of files" do
      es = create_event_stream
      es.events.length.should ==(4)
      es.events.compact.length.should ==(4)
    end

    it "should not generate any events for empty strings" do
      g = ContextGenerator.new(:word_counts)
      File.should_receive(:read).with("/foo/bar").and_return( "\n\n\n\n\n\nonce upon a time\n\n\n\ni ate a sack of mice\n\n\n\n\n\n\n")
      es = FilesetEventStream.new(g, ["/foo/bar"] )

      es.events.length.should ==(2)
    end

    it "should support iteration over the event stream" do
      es = create_event_stream
      events = []
      while(es.hasNext()) do
        events << es.next()
      end

      events.should ==(es.events)
    end

    it "should support resetting of the iterator" do
      es = create_event_stream
      first = es.next()
      es.reset
      first_again = es.next()
      
      first_again.should ==(first)
    end
  end

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
