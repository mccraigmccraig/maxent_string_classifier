module MaxentStringClassifier
  class Event < MODEL::Event
    def initialize(outcome, context, values=nil )
      super(outcome, 
            (context.to_java(:string) if context),
            (values.to_java(:float) if values))
    end
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
end
