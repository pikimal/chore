require 'eventmachine'
require 'evma_httpserver'
require 'chore/store'
require 'json'

# Process submissions from a client and save it in the store.
module ChoreCollect
  @@data_collector = EM.spawn do |chore_info|
    Chore::Store.update_chore(chore_info)
  end

  # Sends data to the data_collector spawned process to add
  # to the data store.
  def chore_collect chore_info
    @@data_collector.notify chore_info
  end

  def receive_data(data)
    chore_info = JSON.parse(data)
    chore_collect chore_info
  end
end

# Provide colorized text output for the CLI interface.
module ChoreDisplay
    def colorize str, color
      color_code = case color
                   when :red then 31
                   when :green then 32
                   when :yellow then 33
                   else raise "BAD COLOR #{str} #{color}"
                   end
      "\033[#{color_code}m#{str}\033[0m"
    end

    def text_statuses

      status_lines = []
      Chore::Store.iterate_statuses do |status|
        status_line = "#{status[:job]} - #{status[:status]}ed #{Time.at(status[:start_time])}"
        status_line += " (#{status[:notes].join(', ')})" if !status[:notes].empty?
        status_lines << colorize(status_line, status[:state])
      end
      
      status_lines.join("\n") + "\n"
    end
    

  def receive_data(data)
    send_data(text_statuses)
    close_connection_after_writing
  end
end

# A basic webserver that provides a single web page with chore
# statues
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

    Chore::Store.iterate_statuses do |status|
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


