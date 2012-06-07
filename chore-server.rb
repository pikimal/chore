require 'eventmachine'

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

  def self.statuses
    ret = []
    ChoreStore.get.each_pair do |key, val|
      status = val[:status]
      run_time = val[:time]
      current_time = Time.now.to_i
      do_every = val[:do_every]
      grace_period = val[:grace_period]

      notes = []
      state = :red

      if status == :fail
        state = :red
        notes << "Job failed"
      elsif do_every
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
        state = :red
        raise "How'd we get here? #{key.inspect} #{val.inspect}"
      end

      ret << colorize("#{key} - #{status}ed #{Time.at(val[:time])} (#{notes.join(', ')})", state)
    end
    
    ret.join("\n") + "\n"
  end

end

module MetricCollect

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
    puts ChoreStore.statuses
  end
end

module MetricDisplay
  def receive_data(data)
    puts "AAAAAA"
    send_data(ChoreStore.statuses)
    close_connection_after_writing
  end
end

EventMachine::run do
  EventMachine::open_datagram_socket('0.0.0.0', 7779, MetricCollect)
  EventMachine::start_server('0.0.0.0', 8888, MetricDisplay)
end
