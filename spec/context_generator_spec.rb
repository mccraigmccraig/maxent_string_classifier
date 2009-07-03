#!/usr/bin/env jspec
raise "JRuby only" if RUBY_PLATFORM !~ /java/i

require 'rubygems'
require 'spec'
require 'yaml'
require 'fileutils'
$: << File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib" ))
require 'maxent_string_classifier'

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
      test_cg(:char_bigram_counts, "one foo23 mon", 
              { "2c:on"=>2, "2c:ne"=>1, "2c:mo"=>1 })
    end

    it "should have a char_trigram_counts featureset which counts character trigrams" do
      test_cg(:char_trigram_counts, "bank 001 ewbanks",
              { "3c:ban"=>2, "3c:ank"=>2, "3c:ewb"=>1, "3c:wba"=>1, "3c:nks"=>1 })
    end

    it "should return an empty Hash if there are no character bigrams" do
      test_cg(:char_bigram_counts, "o", {})
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

    it "should return and empty Hash if there are no bigrams" do
      test_cg(:bigram_counts, "one", {})
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

end
