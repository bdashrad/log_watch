require 'rbconfig'
include RbConfig

def warm_up
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

warm_up

tail_file(ARGV.first) do |data|
  puts data
  if data =~ /error/i
    puts 'ERROR'
    puts 'more coming'
  end
end
