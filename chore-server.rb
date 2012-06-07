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
      run_time = val[:start_time]
      run_time = 0 if !run_time
      current_time = Time.now.to_i
      do_every = val[:do_every]
      grace_period = val[:grace_period]

      notes = []
      state = :red

      if status == :fail
        state = :red
        if val[:error]
          notes << val[:error]
        else
          notes << "FAILED!!!"
        end
        
      elsif status == :finish
        finish_time = val[:finish_time]
        finish_in = val[:finish_in]

        if !finish_in
          state = :green
          notes << "no particular deadline"
        elsif (run_time + finish_in) >= finish_time
          state = :green
          notes << "Finished"
        else
          state = :red
          notes << "Finished, but #{finish_time - (run_time + finish_in)} seconds late!!!"
        end
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
      
      info = {:job => key, :state => state, :status => status, :start_time => run_time, :notes => notes}
      yield info

    end
  end

  def self.text_statuses

    status_lines = []
    iterate_statuses do |status|
      status_line = "#{status[:job]} - #{status[:status]}ed #{Time.at(status[:start_time])}"
      status_line += " (#{status[:notes].join(', ')})" if !status[:notes].empty?
      status_lines << colorize(status_line, status[:state])
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
  end
end

module ChoreDisplay
  def receive_data(data)
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
body {font-family:monospace;background-color:#CCCCCC;}
.red {color:red;}
.yellow {color:yellow;}
.green {color:green;}
table, th, td { border: 1px solid black;}
</style>
</head>
<body>
<h1>Chores</h1>
<table>
<tr><th>Job</th><th>Status</th><th>Time</th><th>Notes</th></tr>
html

    ChoreStore.iterate_statuses do |status|
      row = "<tr class='#{status[:state]}'><td>#{status[:job]}</td><td>#{status[:status]}ed</td><td>#{Time.at(status[:start_time])}</td>"
      if !status[:notes].empty?
        row += "<td>(#{status[:notes].join(', ')})</td>"
      else
        row += "<td>&nbsp;</td>"
      end
      
      row += "</tr>\n"
      html << row 
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
