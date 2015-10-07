# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'log_watch/version'

Gem::Specification.new do |spec|
  spec.name          = 'log_watch'
  spec.version       = LogWatch::VERSION
  spec.authors       = ['Brad Clark']
  spec.email         = ['bdashrad@gmail.com']

  spec.summary       = 'Watch CLF logs and print stuff'
  spec.description   = 'Print interesting data/stats from CLF logs'
  spec.homepage      = 'https://github.com/bdashrad/logwatch'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    fail 'RubyGems 2.0 or newer is required to protect against public pushes.'
  end

  all_files = `git ls-files -z`.split("\x0")
  all_files.reject! { |f| f.match(%r{^(test|spec|features)/}) }
  all_files.reject! { |f| f.match(/^(.gitignore|.rspec|.travis|.rubocop)/) }

  unignored_files = all_files.reject do |file|
    # Ignore any directories, the gemspec only cares about files
    next true if File.directory?(file)
  end

  spec.files         = unignored_files
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rb-inotify', '0.9.5'
  spec.add_runtime_dependency 'rb-kqueue', '0.2.4'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'pry', '0.10.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'rubocop', '0.34.2'
end
