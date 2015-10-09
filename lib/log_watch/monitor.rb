module LogWatch
  # start monitoring a log file
  class Monitor
    def initialize
      # define log format regex
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
      # put loglines into empty array
      @loglines = []
      @total_hits = 0
      @counter = []
      @alert = false
      @threshold = 6
    end

    def start(filename)
      watch_thread = Thread.new { watch_logs(filename) }
      stats_thread = Thread.new { count_hits }
      hits_thread = Thread.new { count_hits_2m }

      # watch the file and start alerting
      watch_thread.join
      stats_thread.join
      hits_thread.join
    end

    private

    def watch_logs(filename)
      Tailer.logtail(filename) do |data|
        unless data.strip == '' # don't process blank lines
          logparts = @log_format.match(data) # match fields
          logentry = Hash[logparts.names.zip(logparts.captures)]
          logentry['section'] = logparts['url'].gsub(%r{((?<!:/)\/\w+).*}, '\1')
          # save time log was recorded, should use log timestamp instead
          @counter.push(Time.now.getutc.to_i)
          @loglines.push(logentry)
          @total_hits += 1
        end
      end
    end

    def count_hits
      loop do
        hits = Hash.new { |h, k| h[k] = 0 }
        @loglines.each do |log|
          hits[log['section']] += 1
        end
        p hits unless hits.length == 0
        sleep 10
      end
    end

    def count_hits_2m
      loop do
        # drop hits older than 2m ago
        @counter.delete_if do |time|
          time < (Time.now.getutc.to_i - (20))
        end
        sleep 1
        if @counter.length >= @threshold && @alert == false
          @alert = true
          alert_traffic(@counter.length)
        end
        if @counter.length < @threshold && @alert == true
          @alert = false
          alert_recovery(@counter.length)
        end
      end
    end

    def alert_traffic(hits)
      time = Time.now.getutc
      p "High traffic generated an alert - hits = #{hits}, triggered at #{time}"
    end

    def alert_recovery(hits)
      time = Time.now.getutc
      p "High traffic event over - hits = #{hits}, triggered at #{time}"
    end
  end
end
