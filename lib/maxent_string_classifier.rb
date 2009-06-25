raise "JRuby only" if RUBY_PLATFORM !~ /java/i

Dir[ File.join( File.dirname(__FILE__), "*.jar") ].each do |f|
  require f
end
require 'yaml'
require 'logger'

# a string classifier based on OpenNLP Maxent model
#
# load a model with e.g.
#   model = MaxentStringClassifier::Loader.load( "language" )
#
# classify with e.g.
#   model.classify( "the kitten thought the mouse was tasty" )
#
# train a model with e.g.
#   MaxentStringClassifier::Loader.train( "language", true, :cutoff=>2 )
#
# features use for the model are extracted by a ContextGenerator,
# and defined in the model.yml file in the model directory.
# see "data/language" and "data/en-email" for example model directories. if
# model directories are not absolute pathnames, then they are resolved
# relative to the "data" directory
#
# training data is in the model directory, in files name "<outcome>.txt",
# with strings separated with empty lines
#
# compiled models are written to the model directory
module MaxentStringClassifier

  VERSION = "0.2.0"

  module Logger
    class << self
      attr_accessor :logger
    end

    self.logger = ::Logger.new($stderr)
    logger.datetime_format="%Y%m%d-%H:%M.%S"
    logger.level = ::Logger::INFO

    def self.included( mod )
      # add the logger method to both instances and class
      mod.instance_eval do
        class << self
          Logger.send(:append_features, self )
        end
      end
    end

    def logger
      Logger.logger
    end
  end

  include Logger

  MAXENT = ::Java::OpennlpMaxent
  MODEL = ::Java::OpennlpMaxent
  IO = ::Java::OpennlpMaxentIo

  GIS = MAXENT::GIS

  class Event < MODEL::Event
    def initialize(outcome, context, values=nil )
      super(outcome, 
            (context.to_java(:string) if context),
            (values.to_java(:float) if values))
    end
  end

  class ContextGenerator
    include Logger

    attr_accessor :featuresets
    attr_accessor :cleanup

    # jruby/joni && ruby1.9/oniguruma regexps are broken, so can't use POSIX [:punct:] class
    # http://jira.codehaus.org/browse/JRUBY-3581
    PUNCT = Regexp.quote( "±§!@\#$%^&*()_-+={[}]:;\"'|\~`<,>.?/" )

    def initialize(featuresets, cleanup = nil)
      @featuresets = [*featuresets].compact
      raise "must give some featureset names" if @featuresets.length == 0
      
      if cleanup.nil?
        @cleanup = Proc.new{ |str| str.gsub( /(\s|^)([#{PUNCT}]*)(\w+)([#{PUNCT}]*)(?=\s|$)/ , '\1\2 \3 \4').gsub(/\s+/,' ') }
      elsif cleanup.is_a? Proc
        @cleanup = cleanup
      else
        raise "cleanup should be a Proc"
      end
    end

    def generate(str)
      context = {}

      # cleanup str text
      str = cleanup.call( str )
      
      featuresets.each do |featureset_name|
        append_featureset_context(context, featureset_name, str)
      end

      context
    end

    def generate_lists(str)
      context = generate(str)
      fs,vs=[],[]
      context.each do |f,v|
        fs << f
        vs << v
      end
      [fs,vs]
    end

    def append_featureset_context(context, featureset_name, str)
      c = self.send(featureset_name.to_s + "_context", str)

      # basically Hash.merge, but raise on duplicate key
      c.each do |feature,v|
        raise "feature name clash: #{feature} from featureset: #{featureset} on str:\n#{str}\n" if context.has_key?(feature)
        context[feature]=v
      end

      context
    end

    module FeatureGenerators
      # def a featureset which defines a single feature by scanning with a regex pattern and counting the result
      def def_regex_feature( name, pattern )
        self.send(:define_method, name.to_s + "_context") do |str|
          { name.to_s => str.scan( pattern ).length }
        end
      end

      # def a featureset which defines a single feature by splitting the str, then selecting with a regex, and counting
      def def_split_select_feature( name, pattern, split_pattern = nil)
        self.send(:define_method, name.to_s + "_context" ) do |str|
          if split_pattern
            { name.to_s => str.split(split_pattern).select{ |w| w=~ pattern }.length }
          else
            { name.to_s => str.split().select{ |w| w =~ pattern }.length }
          end
        end
      end
    end

    class << self
      include FeatureGenerators
    end
    
    # a featureset which defines a feature for each word occuring in the string, with a count
    def word_counts_context( str )
      str.downcase.split().inject(Hash.new(0.0)){ |cnts,str| cnts["w:#{str}"] += 1 ; cnts }
    end

    # a featureset which defines a feature for each character occuring in the string, with a count
    def char_counts_context( str )
      str.gsub( /\s/, "").split('').inject(Hash.new(0.0)){ |cnts,char| cnts["c:#{char}"] += 1 ; cnts}
    end

    def_split_select_feature( :c_token,    /.*/ )
    def_split_select_feature( :c_word,     /[[:alpha:]]+/ )
    def_split_select_feature( :c_cap_word, /[[:upper:]]\w*/ )
    def_split_select_feature( :c_natnum,   /^\d+$/ )

    def_regex_feature( :c_telno,  /([\d\+\-\(\)][\d\+\-\(\)\s]{3,})[^\d\+\-\(\)]/ )
    def_regex_feature( :c_url,   /(?:(?:http|ftp|mailto)\:\S+)|(?:www\.(?:\w+\.)+\w+)/ )
    def_regex_feature( :c_email, /\S+@(?:\w+\.)+\w+/ )
  end

  class FilesetEventStream
    include MODEL::EventStream
    include Logger
    
    attr_reader :context_generator
    attr_accessor :events

    def initialize(context_generator, files = [])
      @context_generator = context_generator
      self.events = []
      @index = 0
      
      raise "no data" if !files || files.empty?

      files.each() do |file|
        outcome = File.basename( file, ".*")
        add_events( outcome, File.read(file).split("\n\n").select{ |p| ! p.strip.empty? } )
      end
    end

    def add_events( outcome, strs )
      strs.each do |str|
        context,values = context_generator.generate_lists( str )
        if context && context.length > 0
          self.events << Event.new( outcome, context, values ) if context && context.length > 0

#          $stdout << "\n\n#{outcome}\n"
#          context.zip(values).each{ |(ctx,val)| $stdout << ctx << " = " << val.to_s << "\n" }
        end
      end
    end

    # maxent 2.5.2 compatability
    def nextEvent()
      self.next()
    end

    def next()
      raise "end of EventStream" if @index >= self.events.length
      @index += 1
      self.events[@index - 1]
    end

    def hasNext()
      @index < self.events.length
    end

    def reset
      @index = 0
    end
  end

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

  module Loader
    include Logger

    def select_model_dir(dir_name)
      dir = [dir_name,
             File.expand_path( File.join( File.dirname( __FILE__ ), "..", "data", dir_name ) )].find{ |d| File.directory?(d)}
      raise "no data at: #{dir_name}" if ! dir
      dir
    end

    def select_model_dir_opts( dir_name )
      dir = select_model_dir(dir_name)
      opts_f = [File.join(dir, "model.yml"),
                File.expand_path(File.join(dir, "..", "model.yml"))].find{ |f| File.file?(f) }
      raise "no model opts at: #{dir}" if ! opts_f

      opts = YAML.load( File.read( opts_f ) )
      logger.debug "using model opts from #{opts_f}:\n#{opts.inspect}"

      [dir,opts]
    end

    def create_context_generator( opts )
      featuresets = opts[:featuresets]
      if featuresets
        logger.debug "using featuresets: #{featuresets.inspect}"
      else
        featuresets = [:word_counts]
        logger.debug "using default featuresets: #{featuresets.inspect}"
      end
      context_generator = ContextGenerator.new( featuresets )
    end

    def model_file( dir )
      File.expand_path( File.join( dir, "#{File.basename( dir )}.txt.gz") )
    end

    def train( dir, persist=true, opts={} )
      dir,opts = select_model_dir_opts( dir )
      logger.debug "reading from model directory: #{dir}"
      
      context_generator = create_context_generator(opts)

      files = Dir[File.join(dir, "*.txt")]
      model = Model.train_from_files( context_generator, files, opts )
      if persist
        model.write( model_file(dir) )
        logger.debug "model written to: #{model_file(dir)}"
      end
      model
    end

    # load a persisted model from the given directory
    def load( dir )
      dir,opts = select_model_dir_opts( dir )
      context_generator = create_context_generator(opts)
      model = Model.load(context_generator, model_file(dir) )
      logger.debug( "model loaded from: #{model_file(dir)}")
      model
    end

    # test a model against the data in the given directory
    def test_against( model, dir, margin=nil )
      dir = select_model_dir( dir )
      logger.debug "testing against model directory: #{dir}"

      results = Hash.new{ |h,outcome| h[outcome] = [0,0] }

      files = Dir[File.join(dir, "*.txt")]
      files.each do |file|
        correct_outcome = File.basename( file, ".*" )
        
        strs = File.read(file).split("\n\n").select{ |p| ! p.strip.empty? }
        
        strs.each do |str|
          if margin
            classification = model.classify_margin(str,margin)
          else
            classification = model.classify_margin(str)
          end
          
          if classification[0][0] == correct_outcome
            results[correct_outcome][0] += 1
          else
            results[correct_outcome][1] += 1
            logger.warn "failure: #{correct_outcome} incorrectly classified: #{classification.inspect}\n#{str}\n\n"
          end
        end
      end
      
      logger.info "\n\nsummary\n#{results.inspect}\n\n"
      results
    end
    
    module_function :select_model_dir 
    module_function :model_file
    module_function :select_model_dir_opts
    module_function :create_context_generator
    module_function :train
    module_function :load
    module_function :test_against
    
  end
end
