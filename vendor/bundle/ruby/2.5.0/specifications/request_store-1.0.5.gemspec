# -*- encoding: utf-8 -*-
# stub: request_store 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "request_store".freeze
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Klabnik".freeze]
  s.date = "2013-01-09"
  s.description = "RequestStore gives you per-request global storage.".freeze
  s.email = ["steve@steveklabnik.com".freeze]
  s.homepage = "http://github.com/steveklabnik/request_store".freeze
  s.rubygems_version = "3.2.3".freeze
  s.summary = "RequestStore gives you per-request global storage.".freeze

  s.installed_by_version = "3.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 3.0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 3.0"])
  end
end
