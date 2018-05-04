
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "oh_my_postgres/version"

Gem::Specification.new do |spec|
  spec.name          = "oh_my_postgres"
  spec.version       = OhMyPostgres::VERSION
  spec.authors       = ["darren.chang"]
  spec.email         = ["darren987469@gmail.com"]

  spec.summary       = %q{Discovery the magic power of postgres!}
  spec.description   = %q{Postgres support json. We can use that feature to do amazing things!}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'benchmark-ips'
  spec.add_dependency 'activerecord-import'
  spec.add_dependency 'colorize'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'coveralls'
end
