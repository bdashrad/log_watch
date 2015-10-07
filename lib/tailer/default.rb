module Tailer
  # tail files when inotify/kqueue are not available
  class Default
    def self.tail(filename)
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
