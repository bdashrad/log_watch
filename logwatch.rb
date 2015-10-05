require 'pp'
require 'rbconfig'
include RbConfig

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

  # open the file and watch with inotify
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

log = LogWatch.new
@loglines = []
log.tail_file(ARGV.first) do |data|
  unless data.strip == ""
    time = data.slice!(/\[.*?\]/)
    request = data.slice!(/".*"/)
    ip, identity, username, status, size = data.split
    verb, path, version = request.gsub(/^"|"$/, '').split
    logline = { 'ip' => ip,
                'identity' => identity,
                'username' => username,
                'time' => time,
                'request' => request,
                'status' => status,
                'size' => size,
                'verb' => verb,
                'path' => path,
                'version' => version
              }
    pp logline
    @loglines.push(logline)
  end
end
