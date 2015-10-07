require 'rbconfig'
include RbConfig

# watch w3c logs and alert on chagnes
class LogTail
  def initialize
    @os = RbConfig::CONFIG['host_os']
  end

  def tail_file(filename)
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
