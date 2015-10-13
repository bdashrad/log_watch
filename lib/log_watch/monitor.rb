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
      @counter = []
      @alert = false
      @threshold = 6
      @total_hits = 0
      @alertqueue = []
      @section_hits = Hash.new { |h, k| h[k] = 0 }
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
          # save time log was recorded, should use log timestamp instead
          @counter.push(Time.now.getutc.to_i)
          # should probably clean up this array to save on memory
          @loglines.push(parse_log_data(data))
          @total_hits += 1
        end
      end
    end

    def count_hits
      loop do
        @loglines.each do |log|
          @section_hits[log['section']] += 1
        end
        show_stats(@section_hits) unless @section_hits.length == 0
        @loglines = []
        sleep 10
      end
    end

    def count_hits_2m
      loop do
        # drop hits older than 2m ago
        @counter.delete_if do |time|
          # if timestamp is older than 2m drop
          time < (Time.now.getutc.to_i - (2 * 60))
        end
        check_alert
        sleep 0.5
      end
    end

    def parse_log_data(data)
      # match fields
      logparts = @log_format.match(data)
      logentry = Hash[logparts.names.zip(logparts.captures)]
      logentry['section'] = logparts['url'].gsub(%r{((?<!:/)\/\w+).*}, '\1')
      logentry
    end

    def check_alert
      if @counter.length >= @threshold && @alert == false
        @alert = true
        alert_traffic(@counter.length)
      elsif @counter.length < @threshold && @alert == true
        @alert = false
        alert_recovery(@counter.length)
      end
    end

    def alert_traffic(hits)
      t = Time.now.getutc
      a = "#{t} | High traffic generated an alert - hits = #{hits}"
      # p a
      @alertqueue.push(a)
      puts @alertqueue.last
    end

    def alert_recovery(hits)
      t = Time.now.getutc
      a = "#{t} | High traffic event over - hits = #{hits}"
      # p a
      @alertqueue.push(a)
      puts @alertqueue.last
    end

    def show_alerts
      @alertqueue.each do |alert|
        puts alert
      end
    end

    def show_stats(hits)
      system 'clear'
      # top 5 sections
      top_hits = hits.sort_by { |_, v| v }.reverse.first(5).to_h
      @alert == false ? stats = 'NORMAL | ' : stats = 'CRITICAL | '
      stats += "Total Hits: #{@total_hits} | "
      stats += "Top Sections: #{top_hits}"
      puts stats
      show_alerts
    end
  end
end
