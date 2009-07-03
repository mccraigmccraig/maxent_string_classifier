#!/usr/bin/env jspec
raise "JRuby only" if RUBY_PLATFORM !~ /java/i

require 'rubygems'
require 'spec'
require 'yaml'
require 'fileutils'
$: << File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib" ))
require 'maxent_string_classifier'

module MaxentStringClassifier

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
end
