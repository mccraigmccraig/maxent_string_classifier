
Gem::Specification.new do |s|
  s.name = %q{maxent_string_classifier}
  s.version = "0.1"
  s.date = %q{2009-04-20}

  s.authors = ["mccraigmccraig"]
  s.description = %q{maxent_string_classifier is a JRuby library, which wraps the OpenNLP Maxent classifier and makes it easy to train and use string classifiers}
  s.email = %q{craig@trampolinesystems.com}
  s.files = Dir["lib/**/*"] + Dir["data/**/*"] +Dir["spec/**/*"] + ["Rakefile"]
  s.files.reject! { |name| name =~ /\.svn|\.git/ }
  s.has_rdoc = false
  s.homepage = %q{http://github.com/mccraigmccraig/maxent_string_classifier}
  s.require_paths = ["lib"]
  s.summary = %q{maxent_string_classifier is a JRuby library for creating string classifiers, based on OpenNLP Maxent}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.requirements << 'none'
end
