# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ios_backup_extractor/version'

Gem::Specification.new do |spec|
  spec.name          = 'ios_backup_extractor'
  spec.version       = IosBackupExtractor::VERSION
  spec.authors       = ['Nauktis']
  spec.email         = ['nauktis@users.noreply.github.com']

  spec.summary       = %q{Ruby script to extract iOS backups.}
  spec.description   = %q{Ruby script to extract iOS backups.}
  spec.homepage      = 'https://github.com/Nauktis/ios_backup_extractor'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'nauktis_utils'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'aes_key_wrap'
  spec.add_dependency 'CFPropertyList'
  spec.add_dependency 'sqlite3'
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec'
end
