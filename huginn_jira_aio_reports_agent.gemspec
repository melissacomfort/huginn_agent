# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_jira_aio_reports_agent"
  spec.version       = '0.1'
  spec.authors       = ["Melissa Comfort"]
  spec.email         = ["mcomfort@convergeone.com"]

  spec.summary       = %q{Trigger email to submitter after submit an issue in Jira or after the status is marked "Done"}
  spec.description   = %q{When someone submits an issue (bug, feature request, etc.) through an issue collector in Jira,
                          we want them to receive a static email on a regularly scheduled basis (e.g., once a day).
                          We would like the email to include their submitted issues(s) and their current, corresponding status(s).
                          The statuses that would trigger inclusion to that individual’s email should be:

                          1. When an issue is submitted, and
                          2. When an issue is marked “Done.”
                             We would like them to receive no more than one email a day.
                             Once the person has received an email stating that their submitted issue is complete, they should not receive another email regarding that issue again.
                             We want the issues submitted for each person in a given time period (e.g., 1 week) to be compiled into one email to comport with the goal of no more than one email/day/person, and proactive relief from excessive communication.

                          3. We want to be able to retrieve submission status to know that the autoresponder ran successfully for both email types per issue.
                             We want to have that shown by automatically marking the issue in a custom field in Jira, once the email is sent for each of 2 statuses: To Do / In Progress, and Done
                        }

  spec.homepage      = "https://github.com/huginn_agent"

  spec.license       = "MIT"


  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.11.2"
  spec.add_development_dependency "guard", "~> 2.13.0"
  spec.add_development_dependency "guard-rspec", "~> 4.6.5"
end
