require 'rb-inotify'

module LogWatch
  module Tailer
    # Tail files in Linux with inotify
    class Linux
      def self.tail(filename)
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
  end
end
