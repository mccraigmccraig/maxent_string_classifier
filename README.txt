= maxent_string_classifier

this code was developed by trampoline systems [ http://trampolinesystems.com ]
as part of its sonar platform and released under a BSD licence for community use

http://www.github.com/mccraigmccraig/maxent_string_classifier

== DESCRIPTION:

a JRuby maxent classifier for string data, based on the OpenNLP Maxent framework
[ http://maxent.sourceforge.net/ ].

it's easy to build your own classifier... look in the data directory for two
examples

== FEATURES:

- train classifiers for string data using files of manually classified examples
- classify string data

== PROBLEMS:

- set of features available for classification is fixed... new features require
code change

== SYNOPSIS:

require 'rubygems'
require 'maxent_string_classifier'

# train and persist a model with a directory name. 
# training data for each outcome is in .txt files in the directory. 
# a model.yml file defines features to be used for contexts, and training params
#
# the model is written as a .txt.gz file in the directory
model = MaxentStringClassifier::Loader.train( "/Users/mccraig/language" )

# load a model with it's directory name. .txt.gz model and model.yml are
# required
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

(The BSD License)

Copyright (c) 2009, Trampoline Systems Ltd, http://trampolinesystems.com/
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the <ORGANIZATION> nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
