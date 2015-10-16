require 'bundler/gem_tasks'
# require 'rspec/core/rake_task'

# RSpec::Core::RakeTask.new(:spec)

# task 'default' => :spec

task :dev do
  sh 'bundle install -j4 --path vendor'
end

task :install do
  sh 'gem build log_watch.gemspec'
  sh 'gem install log_watch'
end

task :spec do
  sh bundle exec rspec spec
end
