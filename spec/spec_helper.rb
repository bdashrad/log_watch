if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec'
    add_filter '/vendor'
  end

  @os = RbConfig::CONFIG['host_os']

  case @os
  when (/bsd|darwin/i)
    require 'log_watch/tailer/bsd'
  when (/linux/)
    require 'log_watch/tailer/linux'
  else
    require 'log_watch/tailer/default'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'log_watch'
