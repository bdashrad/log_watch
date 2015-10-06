require 'rbconfig'
include RbConfig

case RbConfig::CONFIG['host_os']
when (/bsd|darwin/)
  puts 'bsd'
  require 'rb-kqueue'
when (/linux/)
  puts 'linux'
  require 'rb-inotify'
end

module LogTailer
  # watch w3c logs and alert on chagnes
  class LogTail
    def initialize
      # things and stuff
    end

    # open the file and watch for changes
    # maybe i should use the gem filewatch
    def tail_file(filename)
      open(filename) do |file|
        file.seek(0, IO::SEEK_END)
        case RbConfig::CONFIG['host_os']
        when (/bsd|darwin/i)
          puts 'kqueue tail'
          queue = KQueue::Queue.new
          queue.watch_file(filename, :extend) do
            yield file.read
          end
          queue.run
        when (/linux/)
          puts 'inotify tail'
          queue = INotify::Notifier.new
          queue.watch(filename, :modify) do
            yield file.read
          end
          queue.run
        else
          puts 'default tail'
          loop do
            changes = file.read
            yield changes unless changes.empty?
            sleep 1.0
          end
        end
      end
    end
  end

  # Tail files in BSD with kqueue
  class BSDTail
    def tail_file(filename)
      open(filename) do |file|
        file.seek(0, IO::SEEK_END)
        queue = KQueue::Queue.new
        queue.watch_file(filename, :extend) do
          yield file.read
        end
        queue.run
      end
    end
  end

  # Tail files in Linux with inotify
  class LinuxTail
    def tail_file(filename)
      open(filename) do |file|
        file.seek(0, IO::SEEK_END)
        queue = INotify::Notifier.new
        queue.watch(filename, :modify) do
          yield file.read
        end
        queue.run
      end
    end
  end

  # tail files when inotify/kqueue are not available
  class DefaultTail
    def tail_file(filename)
      open(filename) do |file|
        file.seek(0, IO::SEEK_END)
        loop do
          changes = file.read
          yield changes unless changes.empty?
          sleep 1.0
        end
      end
    end
  end
end
