# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git-runner-deploy'

Gem::Specification.new do |gem|
  gem.name          = "git-runner-deploy"
  gem.version       = GitRunner::Instruction::Deploy::VERSION
  gem.authors       = ["James Brooks"]
  gem.email         = ["james@jamesbrooks.net"]
  gem.description   = "Capistrano deploy module for git-runner"
  gem.summary       = "Capistrano deploy module for git-runner"
  gem.homepage      = "https://github.com/JamesBrooks/git-runner-deploy"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency 'git-runner', '>= 0.1.2'
end
