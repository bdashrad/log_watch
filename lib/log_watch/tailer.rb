require 'rbconfig'
include RbConfig

module LogWatch
  # Tailer module
  module Tailer
    autoload :Bsd, 'log_watch/tailer/bsd'
    autoload :Linux, 'log_watch/tailer/linux'
    autoload :Default, 'log_watch/tailer/default'

    @os = RbConfig::CONFIG['host_os']

    def self.logtail(filename)
      case @os
      when (/bsd|darwin/i)
        LogWatch::Tailer::Bsd.tail(filename) do |data|
          yield data
        end
      when (/linux/)
        LogWatch::Tailer::Linux.tail(filename) do |data|
          yield data
        end
      else
        LogWatch::Tailer::Default.tail(filename) do |data|
          yield data
        end
      end
    end
  end
end
