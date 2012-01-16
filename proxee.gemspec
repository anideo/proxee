# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "proxee/version"

Gem::Specification.new do |s|
  s.name        = "proxee"
  s.version     = Proxee::VERSION
  s.authors     = ["Arun Thampi"]
  s.email       = ["arun.thampi@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A Web-Debugging Proxy written using EventMachine}
  s.description = %q{A Web-Debugging Proxy written using EventMachine}

  s.rubyforge_project = "proxee"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency  'eventmachine',   '~> 0.12.10'
  s.add_dependency  'http_parser.rb', '~> 0.5.3'
  s.add_dependency  'uuid',           '~> 2.3.4'
  s.add_dependency  'haml',           '~> 3.1'
  s.add_dependency  'sinatra',        '~> 1.2'
  s.add_dependency  'sqlite3',        '~> 1.3'
  s.add_dependency  'thin',           '~> 1.2'
  s.add_dependency  'activesupport',  '~> 3.1.3'
  s.add_dependency  'json',           '~> 1.6.5'

  s.add_development_dependency  'rspec',  '~> 2.6.0'
end
