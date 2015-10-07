require 'rb-kqueue'

module LogWatch
  module Tailer
    # Tail files in BSD with kqueue
    class Bsd
      def self.tail(filename)
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
  end
end
