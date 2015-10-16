if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec'
    add_filter '/vendor'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'log_watch'
