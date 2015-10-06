ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', __FILE__)

require 'rbconfig'
include RbConfig

# watch w3c logs and alert on chagnes
module LogTailer
  class LogTail
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
end
