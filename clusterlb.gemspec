
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "clusterlb/version"

Gem::Specification.new do |spec|
  spec.name          = "clusterlb"
  spec.version       = Clusterlb::VERSION
  spec.authors       = ["Dr. Ogg"]
  spec.email         = ["ogg@sr375.com"]

  spec.summary       = "Simple tools to manage a group of nginx lb's"
  spec.description   = "Simple tools to manage a group of nginx lb's with shared nfs configs"
  spec.license       = "MIT"
  spec.required_ruby_version =  Gem::Requirement.new('>= 2.2')

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0.2"
  spec.add_development_dependency "rake", "~> 12.3.2"
  spec.add_dependency 'colorize', '~> 0.8.1'
  spec.add_dependency 'console_table', '~> 0.3.0'
  spec.add_dependency 'fileutils',  '= 0.7.2'
  spec.add_dependency 'json',  '~> 2.2', '>= 2.2.0'
  spec.add_dependency 'inifile',  '~> 3.0', '>= 3.0.0'
  # spec.add_dependency 'aws-sdk', '~> 3.0', '>= 3.0.1'
  spec.add_dependency 'aws-sdk-s3', '~> 1.46'
  spec.add_dependency 'net-ssh', '~> 5.2'
end
