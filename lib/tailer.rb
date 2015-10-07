require 'rbconfig'
include RbConfig

# Tailer module
module Tailer
  autoload :Bsd, 'tailer/bsd'
  autoload :Linux, 'tailer/linux'
  autoload :Default, 'tailer/default'
  # autoload :LogTail, 'tailer/log_tail'

  def self.logtail(filename)
    case @os
    when (/bsd|darwin/i)
      Tailer::Bsd.tail(filename) do |data|
        yield data
      end
    when (/linux/)
      Tailer::Linux.tail(filename) do |data|
        yield data
      end
    else
      Tailer::Default.tail(filename) do |data|
        yield data
      end
    end
  end
end
