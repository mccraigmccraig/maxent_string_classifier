= maxent_string_classifier

http://www.github.com/mccraigmccraig/maxent_string_classifier

== DESCRIPTION:

a JRuby maxent classifier for string data, based on the OpenNLP Maxent framework.

it's easy to build your own classifier... look in the data directory for two examples

== FEATURES/PROBLEMS:

* FIX (list of features or problems)

== SYNOPSIS:

require 'rubygems'
require 'maxent_string_classifier'

# train and persist a model with a directory name. 
# training data for each outcome is in .txt files in the directory. 
# a model.yml file defines features to be used for contexts, and training params
#
# is written as a .txt.gz file in the directory
model = MaxentStringClassifier::Loader.train( "/Users/mccraig/language" )

# load a model with it's directory name. .txt.gz model and model.yml are required
model = MaxentStringClassifier::Loader.load( "/Users/mccraig/language" )

# classify
model.classify( "je voudrais une chambre" )
model.classify( "i am going to buy an elephant" )

# classify with a margin of certainty
model.classify_margin( "i am une chambre", 1.1)

# models in data dir are loaded with relative path
MaxentStringClassifier::Loader.load( "language" )

== REQUIREMENTS:

JRuby

== INSTALL:

sudo jgem sources -a http://gems.github.com
sudo jgem install mccraigmccraig-maxent_string_classifier

== LICENSE:

(The MIT License)

Copyright (c) 2009 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
