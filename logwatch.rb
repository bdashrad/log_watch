require 'pp'
require 'rbconfig'
include RbConfig

@log_format = /
  \A
  (?<ip>\S+)\s
  (?<identity>\S+)\s
  (?<user>\S+)\s
  \[(?<time>[^\]]+)\]\s
  "(?<verb>[A-Z]+)\s
  (?<url>\S+)\s
  (?<version>\S+?)"\s
  (?<status>\d+)\s
  (?<bytes>\S+)
/x

# watch w3c logs and alert on chagnes
class LogWatch
  def initialize
    @os = RbConfig::CONFIG['host_os'] # string with OS name
    load_os_gems
  end

  def load_os_gems
    case @os
    when (/bsd|darwin/)
      require 'rb-kqueue'
    when (/linux/)
      require 'rb-inotify'
    end
  end

  # open the file and watch for changes
  def tail_file(filename)
    open(filename) do |file|
      file.seek(0, IO::SEEK_END)
      case @os
      when (/bsd|darwin/)
        queue = KQueue::Queue.new
        queue.watch_file(filename, :extend) do
          yield file.read
        end
        queue.run
      when (/linux/)
        queue = INotify::Notifier.new
        queue.watch(filename, :modify) do
          yield file.read
        end
        queue.run
      else
        loop do
          changes = file.read
          unless changes.empty? yield changes
          end
          sleep 1.0
        end
      end
    end
  end
end

def watch_logs(log)
  log.tail_file(ARGV.first) do |data|
    unless data.strip == '' # don't process blank lines
      logparts = @log_format.match(data) # match fields
      logentry = Hash[logparts.names.zip(logparts.captures)]
      logentry['section'] = logparts['url'].gsub(%r{((?<!:/)\/\w+).*}, '\1')
      p logentry
      @loglines.push(logentry)
      count_hits
    end
  end
end

def count_hits
  hits = Hash.new{ |h,k| h[k]=0 }
  p @loglines.length
  @loglines.each do |log|
    hits[log['section']] += 1
  end
  p hits
end

@loglines = []
watch_logs(LogWatch.new)
