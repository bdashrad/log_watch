require 'rbconfig'
include RbConfig

case RbConfig::CONFIG['host_os']
when (/bsd|darwin/)
  require 'rb-kqueue'
when (/linux/)
  require 'rb-inotify'
end

# watch w3c logs and alert on chagnes
class LogTail
  def initialize
    @os = RbConfig::CONFIG['host_os']
  end

  # open the file and watch for changes
  # maybe i should use the gem filewatch
  def tail_file(filename)
    case @os
    when (/bsd|darwin/i)
      puts 'bsd'
      BSDTail.new.tail(filename)
    when (/linux/)
      queue = INotify::Notifier.new
      queue.watch(filename, :modify) do
        yield file.read
      end
      queue.run
    else
      loop do
        changes = file.read
        yield changes unless changes.empty?
        sleep 1.0
      end
    end
  end
end

# Tail files in BSD with kqueue
class BSDTail
  def tail(filename)
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
  def tail(filename)
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
  def tail(filename)
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
