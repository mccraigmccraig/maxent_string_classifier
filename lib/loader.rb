module MaxentStringClassifier
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
