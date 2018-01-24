lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'achis/version'

Gem::Specification.new do |spec|
  spec.name          = "achis"
  spec.version       = Achis::VERSION
  spec.authors       = ["Eloy Espinaco", "Gaston Ramos"]
  spec.email         = ["eloyesp@gmail.com", "ramos.gaston@gmail.com"]
  spec.summary       = 'Automated Clearing House Integration System'
  spec.description   = 'Gem to integrate ACH with different providers.'
  spec.homepage      = ""
  spec.license       = "GPL"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rubocop", "~> 0.27.0"
  spec.add_development_dependency "guard-rubocop"

  spec.add_dependency "net-sftp", "~> 2.1.2"
  spec.add_dependency "validated_accessors", "~> 0.1"
  spec.add_dependency "double-bag-ftps", "~> 0.1.2"
  spec.add_dependency "guevara", "~> 0.2"
end
