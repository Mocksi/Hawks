# frozen_string_literal: true

# hawksi.gemspec
require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name          = 'hawksi'
  spec.version       = Hawksi::VERSION
  spec.authors       = ['Mocksi Engineering']
  spec.email         = ['engineering@mocksi.ai']

  spec.summary       = 'Hawksi: Rack middleware to the Mocksi API.'
  spec.description   = 'Hawksi sits between your application and the Mocksi API,\n'
  spec.description +=  'allowing our agents to learn from your app to simulate whatever you can imagine.'
  spec.homepage      = 'https://github.com/Mocksi/hawksi'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Mocksi/hawksi/README.md'
  spec.metadata['changelog_uri'] = 'https://github.com/Mocksi/hawksi/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      %w[test spec features .gitignore hawksi.gemspec].include?(f) ||
        f.match?(%r{(^\.|/\.\.|\.\./|\.git|\.hg|CVS|\.svn|\.lock|~$)}) ||
        f.end_with?('.gem') # Exclude gem files
    end
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'httpx', '~> 1.3'
  spec.add_dependency 'json', '~> 2.5'
  spec.add_dependency 'puma', '~> 5.0'
  spec.add_dependency 'rack', '~> 2.2'
  spec.add_dependency 'thor', '~> 1.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
