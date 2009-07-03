#!/usr/bin/env ruby

require 'constants'
module MaxentStringClassifier
  class Model
    include Logger

    attr_reader :maxent_model
    attr_reader :context_generator
    
    def initialize( maxent_model, context_generator )
      @maxent_model = maxent_model
      @context_generator = context_generator
    end

    def classify(str)
      context,values = context_generator.generate_lists(str)
      vals = @maxent_model.eval( context.to_java(:string), values.to_java(:float) )
      r = []
      vals.each_with_index{ |n, i| r << [@maxent_model.get_outcome(i), n] }
      r.sort{ |(aname,aprob),(bname,bprob)| bprob <=> aprob }
    end

    def classify_margin(str, margin=1.1)
      r = classify(str)

      if r[0][1] >= margin * r[1][1]
        # principal classification exceeded secondary by given margin
        r
      else
        # classification was uncertain...
        [[nil,nil]] + r
      end
    end

    def write(file)
      writer = IO::SuffixSensitiveGISModelWriter.new( @maxent_model, ::Java::JavaIo::File.new(file) )
      writer.persist
      self
    end

    def self.load(context_generator, file)
      reader = IO::SuffixSensitiveGISModelReader.new( ::Java::JavaIo::File.new( file ))
      new( reader.getModel(), context_generator )
    end

    DEFAULT_TRAIN_OPTS = { 
      :iterations => 100,
      :cutoff => 0,
      :smoothing => false
    }

    def self.train_from_files( context_generator, files, opts={} )
      opts = DEFAULT_TRAIN_OPTS.merge( opts )
      opts[:print_messages ] = logger.level <= ::Logger::DEBUG

      es = FilesetEventStream.new(context_generator, files )

      maxent_model = GIS.trainModel( es,
                                     opts[:iterations],
                                     opts[:cutoff],
                                     opts[:smoothing],
                                     opts[:print_messages] )
      new( maxent_model, context_generator )
    end
  end
end
