# -*- encoding: utf-8 -*-
# stub: blankslate 3.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "blankslate".freeze
  s.version = "3.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jim Weirich".freeze, "David Masover".freeze, "Jack Danger Canty".freeze]
  s.date = "2014-06-18"
  s.email = "rubygems@6brand.com".freeze
  s.homepage = "http://github.com/masover/blankslate".freeze
  s.rubygems_version = "3.2.3".freeze
  s.summary = "BlankSlate extracted from Builder.".freeze

  s.installed_by_version = "3.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
  end
end
