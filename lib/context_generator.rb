module MaxentStringClassifier
  class ContextGenerator
    include Logger

    attr_accessor :featuresets
    attr_accessor :cleanup_proc

    # jruby/joni && ruby1.9/oniguruma regexps are broken, so can't use POSIX [:punct:] class
    # http://jira.codehaus.org/browse/JRUBY-3581
    PUNCT = Regexp.quote( "±§!@\#$%^&*()_-+={[}]:;\"'|\~`<,>.?/" )

    def initialize(featuresets, cleanup = nil)
      @featuresets = [*featuresets].compact
      raise "must give some featureset names" if @featuresets.length == 0
      
      if cleanup.nil?
        @cleanup_proc = Proc.new{ |str| str.gsub( /(\s|^)([#{PUNCT}]*)(\w+)([#{PUNCT}]*)(?=\s|$)/ , '\1\2 \3 \4').gsub(/\s+/,' ').gsub(/\\[tnrfbaes]/, ' ') }
      elsif cleanup.is_a? Proc
        @cleanup_proc = cleanup
      else
        raise "cleanup should be a Proc"
      end
    end

    def cleanup(str)
      cleanup_proc.call(str)
    end

    def generate(str)
      context = {}

      # cleanup str text
      str = cleanup( str )
      
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
        self.send(:define_method, name.to_s + "_scan") do |str|
          str.scan( pattern )
        end

        self.send(:define_method, name.to_s + "_context") do |str|
          { name.to_s => self.send( name.to_s + "_scan", str ).length }
        end
      end

      # def a featureset which defines a single feature by splitting the str, then selecting with a regex, and counting
      def def_split_select_feature( name, pattern, split_pattern = nil)
        self.send(:define_method, name.to_s + "_split" ) do |str|
          if split_pattern
            str.split(split_pattern)
          else
            str.split
          end
        end

        self.send( :define_method, name.to_s + "_select") do |strs|
          strs.select{ |w| w=~ pattern }
        end

        self.send( :define_method, name.to_s + "_split_select" ) do |str|
          strs = self.send(name.to_s + "_split", str)
          self.send(name.to_s + "_select", strs )
        end

        self.send(:define_method, name.to_s + "_context" ) do |str|
          { name.to_s => self.send(name.to_s + "_split_select", str).length }
        end
      end

      # def a featureset which currys some args into another method
      def def_curry_feature( name, curried_method_name, *curry_args )
        curried_method = self.instance_method(curried_method_name.to_s)
        self.send(:define_method, name.to_s + "_context" ) do |str|
          curried_method.bind(self).call( str, *curry_args )
        end
      end
    end

    class << self
      include FeatureGenerators
    end
    
    # word ngrams from [:alpha:] only words
    def ngram_counts_context(str, n)
      toks = str.downcase.split
      shifted = []
      (1...n).each{ |i| shifted << toks[i..-1] }
      n_grams = toks.zip(*shifted).select{ |n_gram| n_gram.select{ |w| w=~ /^[[:alpha:]]+$/ }.length==n }
      n_grams.inject(Hash.new(0.0)){ |cnts,n_gram| cnts["#{n}w:#{n_gram.join('_')}"]+=1 ; cnts}
    end

    # character ngrams from [:alpha:] only words
    def char_ngram_counts_context(str, n)
      toks = str.downcase.split.select{ |w| w =~ /^[[:alpha:]]+$/ }
      cnts = Hash.new(0.0)
      toks.each do |tok|
        chars = tok.split("")
        shifted=[]
        (1...n).each{ |i| shifted << chars[i..-1] }
        n_grams = chars.zip(*shifted).select{ |n_gram| n_gram.length == n_gram.compact.length }
        n_grams.each{ |n_gram| cnts["#{n}c:#{n_gram.join("")}"] += 1} 
      end
      cnts
    end

    def_curry_feature( :word_counts, :ngram_counts_context, 1 )
    def_curry_feature( :bigram_counts, :ngram_counts_context, 2 )
    def_curry_feature( :trigram_counts, :ngram_counts_context, 3 )

    def_curry_feature( :char_counts, :char_ngram_counts_context, 1)
    def_curry_feature( :char_bigram_counts, :char_ngram_counts_context, 2)
    def_curry_feature( :char_trigram_counts, :char_ngram_counts_context, 3)

    def_split_select_feature( :c_token,    /.*/ )
    def_split_select_feature( :c_word,     /[[:alpha:]]+/ )
    def_split_select_feature( :c_cap_word, /[[:upper:]]\w*/ )
    def_split_select_feature( :c_natnum,   /^\d+$/ )
    def_split_select_feature( :c_punct, /(^[#{PUNCT}]+\w*)|(\w*[#{PUNCT}]+)$/ )
    def_split_select_feature( :c_path, /\S+/ )

    def_regex_feature( :c_telno,  /([\d\+\-\(\)][\d\+\-\(\)\s]{3,})(?:[^\d\+\-\(\)]|$)/ )
    def_regex_feature( :c_url,   /(?:(?:http|ftp|mailto)\:\S+)|(?:www\.(?:\w+\.)+\w+)/ )
    def_regex_feature( :c_email, /\S+@(?:\w+\.)+\w+/ )
  end
end
