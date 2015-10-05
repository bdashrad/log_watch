require 'rbconfig'
include RbConfig

# open the file and watch with inotify
def tail_dash_f(filename)
  open(filename) do |file|
    file.seek(0, IO::SEEK_END)
    # string with OS name, like "amd64-freebsd8"
    case RbConfig::CONFIG['host_os']
    when (/bsd|darwin/)
      require 'rb-kqueue'
      queue = KQueue::Queue.new
      queue.watch_file(filename, :extend) do
        yield file.read
      end
      queue.run
    when (/linux/)
      require 'rb-inotify'
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

tail_dash_f(ARGV.first) do |data|
  puts data
  if data =~ /error/i
  puts "ERROR"
  end
end
