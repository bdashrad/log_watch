module LogWatch
  # start monitoring a log file
  class Monitor
    def initialize
      # define log format regex
      # replace with ApacheLogRegex gem?
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
      @loglines ||= [] # put loglines into empty array
      @counter ||= [] # how many hits in the last 2 min
      @alert ||= false # we start off not alerting
      @threshold ||= 6 # how many hits per 2 min is ok
      @total_hits ||= 0 # how many total hits since we started
      @alertqueue ||= [] # a place to hold all of our alerts
      @section_hits ||= Hash.new { |h, k| h[k] = 0 } # start all secitons at 0
      @status ||= Hash.new { |h, k| h[k] =  0 } # track HTTP response codes
      @verbs ||= Hash.new { |h, k| h[k] = 0 } # track HTTP methods
    end

    def start(filename)
      watch_thread = Thread.new { watch_logs(filename) }
      stats_thread = Thread.new do
        loop do
          count_section_hits
          # if we have hits show some stats
          show_stats unless @section_hits.length == 0
          sleep 10
        end
      end
      hits_thread = Thread.new do
        loop do
          count_hits_2m
          check_alert
          sleep 0.5
        end
      end

      # watch the file and start alerting
      watch_thread.join
      stats_thread.join
      hits_thread.join
    end

    # private

    def watch_logs(filename)
      Tailer.logtail(filename) do |data|
        unless data.strip == '' # don't process blank lines
          # save time log was recorded, should use log timestamp instead
          @counter.push(Time.now.utc.to_i)
          # should probably clean up this array to save on memory
          @loglines.push(parse_log_data(data))
          @total_hits += 1
        end
      end
    end

    def count_section_hits
      # lets look what we got so far
      @loglines.each do |log|
        # add count to each section
        @section_hits[log['section']] += 1
        @verbs[log['verb']] += 1
        @status[log['status']] += 1
      end
      # # if we have hits show some stats
      # show_stats(@section_hits) unless @section_hits.length == 0
      # reset current hits
      @loglines = []
    end

    def count_hits_2m(timenow = Time.now.utc.to_i)
      # drop hits older than 2m ago
      @counter.delete_if do |time|
        # if timestamp is older than 2m drop
        time < (timenow - (2 * 60))
      end
    end

    def parse_log_data(data)
      # match fields
      logparts = @log_format.match(data)
      # turn match into a real hash
      logentry = Hash[logparts.names.zip(logparts.captures)]
      # give section it's own key
      logentry['section'] = logparts['url'].gsub(%r{((?<!:/)\/\w+).*}, '\1')
      logentry
    end

    def check_alert
      # if we're not in alert mode and cross the threshold we gotta know
      if @counter.length >= @threshold && @alert == false
        @alert = true
        alert_traffic(@counter.length)
      # if we're in alert mode and drop to ok again tell us
      elsif @counter.length < @threshold && @alert == true
        @alert = false
        alert_recovery(@counter.length)
      end
    end

    def alert_traffic(hits)
      # push a crit into the alerts array and
      # print latest alert so we don't miss any
      a = "#{Time.now.utc} | High traffic generated an alert - hits = #{hits}"
      @alertqueue.push(a)
      puts @alertqueue.last
    end

    def alert_recovery(hits)
      # push a recovery into the alerts array and
      # print latest alert so we don't miss any
      a = "#{Time.now.utc} | High traffic event over - hits = #{hits}"
      @alertqueue.push(a)
      puts @alertqueue.last
    end

    def show_stats
      # shuold probably do this all in ncurses or something
      # instead of clearing the screen and printing it all over again
      system 'clear'
      @alert == false ? stats = 'NORMAL | ' : stats = 'CRITICAL | '
      stats += "Total Hits: #{@total_hits}"
      puts stats
      show_stats_sections
      show_stats_methods
      show_stats_status
      show_alerts
    end

    def show_stats_sections
      # top 5 sections
      top_hits = @section_hits.sort_by { |_, v| v }.reverse.first(5).to_h
      puts "Top Sections: #{top_hits}"
    end

    def show_stats_methods
      # top five http methods
      top_methods = @verbs.sort_by { |_, v| v }.reverse.first(5).to_h
      puts "Top Methods: #{top_methods}"
    end

    def show_stats_status
      # top 5 http status codes
      top_status = @status.sort_by { |_, v| v }.reverse.first(5).to_h
      puts "Top Status: #{top_status}"
    end

    def show_alerts
      # print all alerts we've had so far
      puts '--- ALERTS ---'
      @alertqueue.each do |alert|
        puts alert
      end
    end
  end
end
