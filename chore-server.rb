require 'eventmachine'
require 'evma_httpserver'

module ChoreStore
  @@store = {}

  def self.get
    @@store
  end

  def self.colorize str, color
    color_code = case color
                 when :red then 31
                 when :green then 32
                 when :yellow then 33
                 else raise "BAD COLOR #{str} #{color}"
                 end
    "\033[#{color_code}m#{str}\033[0m"
  end

  def self.iterate_statuses
    ret = []
    ChoreStore.get.each_pair do |key, val|
      status = val[:status]
      run_time = val[:run_time]
      current_time = Time.now.to_i
      do_every = val[:do_every]
      grace_period = val[:grace_period]

      notes = []
      state = :red

      if status == :fail
        state = :red
        notes << "Job failed"
      elsif status == :finish
        state = :green
        notes << "Finished"
      elsif status == :start
        if do_every
          if run_time + do_every >= current_time
            state = :green
          elsif grace_period && run_time + do_every + grace_period > current_time
            state = :yellow
            notes << "Job should run every #{do_every} seconds, but has a grace period of #{grace_period} seconds"
          else
            state = :red
            notes << "Job should run every #{do_every} seconds, but hasn't run since #{run_time}"
          end
        else
          state = :green
          notes << "No regular schedule."
        end
      end
      
      info = {:job => key, :state => state, :status => status, :run_time => run_time, :notes => notes}
      yield info

    end
  end

  def self.text_statuses

    status_lines = []
    iterate_statuses do |status|
      status_lines << colorize("#{status[:job]} - #{status[:status]}ed #{Time.at(status[:run_time])} (#{status[:notes].join(', ')})", status[:state])
    end
    
    status_lines.join("\n") + "\n"
  end
  
end


module ChoreCollect

  def receive_data(data)
    chore_info = eval(data)
    start_or_finish = chore_info[0]
    chore = chore_info[1]
    opts = chore_info[2]
    opts[:status] = start_or_finish
    
    if ChoreStore.get[chore].nil?
      ChoreStore.get[chore] = {}
    end

    ChoreStore.get[chore] = ChoreStore.get[chore].merge(opts)
    puts ChoreStore.text_statuses
  end
end

module ChoreDisplay
  def receive_data(data)
    puts "AAAAAA"
    send_data(ChoreStore.text_statuses)
    close_connection_after_writing
  end
end

class ChoreWeb < EventMachine::Connection
  include EventMachine::HttpServer

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new(self)

    html = <<-html
<html>
<head>
<style type="text/css">
.red {color:red;}
.yellow {color:yellow;}
.green {color:green;}
</style>
</head>
<body>
<h1>Chores</h1>
<table>
html

    ChoreStore.iterate_statuses do |status|
      html << "<tr><td class='#{status[:state]}'>#{status[:job]} - #{status[:status]}ed #{Time.at(status[:run_time])} (#{status[:notes].join(', ')})<tr><td>\n"
    end

    html << "</body></html>"

    resp.status = 200
    resp.content = html
    resp.send_response
  end
  
end


EventMachine::run do
  EventMachine::open_datagram_socket('0.0.0.0', 7779, ChoreCollect)
  EventMachine::start_server('0.0.0.0', 8888, ChoreDisplay)
  EventMachine::start_server('0.0.0.0', 8899, ChoreWeb)
end
