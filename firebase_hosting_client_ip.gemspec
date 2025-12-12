# frozen_string_literal: true

require_relative "lib/firebase_hosting_client_ip/version"

Gem::Specification.new do |spec|
  spec.name = "firebase_hosting_client_ip"
  spec.version = FirebaseHostingClientIp::VERSION
  spec.authors = ["Erich N Quintero"]
  spec.email = ["qbantek@gmail.com"]

  spec.summary = "Rails middleware to normalize client IP behind Firebase Hosting"
  spec.description = "Provides a Rails middleware that resolves the correct client IP when " \
                     "an application is deployed behind Firebase Hosting, using a heuristic " \
                     "precedence of headers."
  spec.homepage = "https://github.com/quintsys/firebase_hosting_client_ip"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 3.0"
  spec.add_dependency "rails", ">= 7.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
