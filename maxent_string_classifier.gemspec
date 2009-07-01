Gem::Specification.new do |s|
  s.name = %q{maxent_string_classifier}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["craig mcmillan"]
  s.date = %q{2009-06-30}
  s.description = %q{maxent_string_classifier is a JRuby library, which wraps the OpenNLP Maxent classifier and makes it easy to train and use string classifiers}
  s.email = %q{craig@trampolinesystems.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "data/language/af.txt", "data/language/de.txt", "data/language/en.txt", "data/language/fr.txt", "data/language/language.txt.gz", "data/language/model.yml", "data/language/no.txt", "data/language/test/af.txt", "data/language/test/de.txt", "data/language/test/en.txt", "data/language/test/fr.txt", "data/language/test/no.txt", "init.rb", "lib/maxent-2.5.2.jar", "lib/maxent_string_classifier.rb", "lib/trove.jar", "maxent_string_classifier.gemspec", "spec/maxent_string_classifier_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{this code was developed by trampoline systems [ http://trampolinesystems.com ]}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{maxent_string_classifier}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{a JRuby maxent classifier for string data, based on the OpenNLP Maxent framework [ http://maxent.sourceforge.net/ ]}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.12.2"])
    else
      s.add_dependency(%q<hoe>, [">= 1.12.2"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.12.2"])
  end
end
