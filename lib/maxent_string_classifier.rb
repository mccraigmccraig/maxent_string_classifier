raise "JRuby only" if RUBY_PLATFORM !~ /java/i

Dir[ File.join( File.dirname(__FILE__), "*.jar") ].each do |f|
  require f
end
require 'yaml'
require 'logger'
require 'maxent_logger'
require 'constants'
require 'context_generator'
require 'fileset_event_stream'
require 'model'
require 'loader'

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
  include Logger

  VERSION = "0.2.0"
end
